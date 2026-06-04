import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../domain/entities/voxia_result.dart';
import '../domain/entities/voxia_session_state.dart';
import '../domain/ports/sound_player.dart';
import '../infrastructure/sound/audio_sound_player.dart';

class VoxiaController extends ChangeNotifier {
  VoxiaController({
    required SpeechToText speech,
    required FlutterTts tts,
    required SoundPlayer soundPlayer,
    Duration silenceTimeout = const Duration(minutes: 3),
    Duration listenFor = const Duration(minutes: 2),
  }) : _speech = speech,
       _tts = tts,
       _soundPlayer = soundPlayer,
       _silenceTimeout = silenceTimeout,
       _listenFor = listenFor;

  factory VoxiaController.defaultInstance({
    Duration silenceTimeout = const Duration(minutes: 3),
    Duration listenFor = const Duration(minutes: 2),
  }) {
    return VoxiaController(
      speech: SpeechToText(),
      tts: FlutterTts(),
      soundPlayer: AudioSoundPlayer(),
      silenceTimeout: silenceTimeout,
      listenFor: listenFor,
    );
  }

  final SpeechToText _speech;
  final FlutterTts _tts;
  final SoundPlayer _soundPlayer;
  final Duration _silenceTimeout; // Asi sea grande no excede el nativo
  final Duration _listenFor;
  bool _isSpeaking = false;

  VoxiaSessionState _state = VoxiaSessionState.initial();
  VoxiaSessionState get state => _state;

  bool get isSpeaking => _isSpeaking;

  Timer? _silenceTimer;
  String? _previousRecognizedText;
  bool _forceStop = false;

  final List<String> _logLines = [];
  List<String> get logLines => List.unmodifiable(_logLines);

  Future<VoxiaResult<void>> login() async {
    if (_state.status == SessionStatus.initializing) {
      return VoxiaResult.failure('Ya hay un inicio de sesión en curso.');
    }

    _updateState(
      _state.copyWith(status: SessionStatus.initializing, lastError: null),
    );

    _appendLog('Iniciando sesión de voz');
    debugPrint('😁😁Iniciando sesión de voz');

    // Verificar permiso de micrófono
    final micResult = await _checkMicrophonePermission();
    if (!micResult.isSuccess) {
      _updateState(
        _state.copyWith(
          status: SessionStatus.error,
          lastError: micResult.error,
          speechEnabled: false,
        ),
      );
      return micResult;
    }

    // Verificar conectividad (STT requiere internet en la mayoría de dispositivos)
    final connResult = await _checkConnectivity();
    if (!connResult.isSuccess) {
      _updateState(
        _state.copyWith(
          status: SessionStatus.error,
          lastError: connResult.error,
          speechEnabled: false,
        ),
      );
      return connResult;
    }

    try {
      await _initializeTts();
      await _initializeSpeech();
      return VoxiaResult.success(null);
    } catch (e) {
      _appendLog('Error al iniciar: $e');
      final errorMsg = '$e';
      _updateState(
        _state.copyWith(
          status: SessionStatus.error,
          lastError: errorMsg,
          speechEnabled: false,
        ),
      );
      return VoxiaResult.failure(errorMsg);
    }
  }

  Future<VoxiaResult<void>> startListening() async {
    if (!_state.canListen) {
      const msg = 'El controlador de voz no está listo para escuchar. '
          'Asegúrate de que login() fue exitoso.';
      _updateState(_state.copyWith(lastError: msg));
      return VoxiaResult.failure(msg);
    }

    if (_isSpeaking) {
      await stopSpeak();
      // Un pequeño delay opcional para dejar que el hardware de audio respire
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _appendLog('start listening');
    _cancelSilenceTimer();
    _previousRecognizedText = null;
    _forceStop = false;
    _updateState(
      _state.copyWith(
        isListening: true,
        silenceStopPending: false,
        hasSpoken: false,
        lastError: null,
      ),
    );

    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: _listenFor,
      pauseFor: _silenceTimeout,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
      localeId: _state.localeId.isEmpty ? null : _state.localeId,
    );
    return VoxiaResult.success(null);
  }

  Future<void> stopListening() async {
    _forceStop = true;
    _previousRecognizedText = null;
    _appendLog('stop listening');
    _cancelSilenceTimer();
    await _speech.stop();
    _updateState(
      _state.copyWith(
        isListening: false,
        silenceStopPending: false,
        hasSpoken: false,
        lastError: null,
      ),
    );
  }

  Future<void> speakText([String? text]) async {
    final content = text?.trim().isNotEmpty == true
        ? text!.trim()
        : _state.recognizedText;
    if (content.isEmpty) {
      return;
    }

    if (_state.isListening) {
      await stopListening();
    }

    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    _appendLog('tts speak: "$content"');

    await _tts.speak(content);
  }

  Future<void> stopSpeak() async {
    _appendLog('tts stop');

    _isSpeaking = false;
    await _tts.stop();
  }

  Future<void> playNotification({
    String assetPath = 'sounds/notification.m4r',
  }) async {
    try {
      _appendLog('play sound: $assetPath');

      await _soundPlayer.play(assetPath);
    } catch (e) {
      _appendLog('Error al reproducir sonido: $e');

      // No lanzamos el error, solo lo registramos para no interrumpir el flujo
    }
  }

  Future<void> logout() async {
    if (_state.status == SessionStatus.loggedOut) return;

    _appendLog('Cerrando sesión de voz');

    _cancelSilenceTimer();
    _previousRecognizedText = null; // Limpiar texto previo
    try {
      await _speech.stop();
    } catch (_) {
      // ignore stop errors
    }
    try {
      await _tts.stop();
    } catch (_) {
      // ignore stop errors
    }
    _logLines.clear();
    _updateState(VoxiaSessionState.initial());
  }

  void clearRecognizedText() async {
    if (_state.recognizedText.isEmpty && !_state.hasSpoken) return;

    if (_isSpeaking) {
      await stopSpeak();
    }

    _appendLog('Clearing recognized text');
    _previousRecognizedText = null; // Limpiar texto previo también
    _updateState(_state.copyWith(recognizedText: '', hasSpoken: false));
  }

  @override
  void dispose() {
    _cancelSilenceTimer();
    _previousRecognizedText = null;
    _forceStop = false;
    _logLines.clear();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<VoxiaResult<void>> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (result.isEmpty || result.first.rawAddress.isEmpty) {
        const msg = 'Sin conexión a internet. Voxia requiere conexión para el reconocimiento de voz.';
        _appendLog(msg);
        return VoxiaResult.failure(msg);
      }
      return VoxiaResult.success(null);
    } on SocketException {
      const msg = 'Sin conexión a internet. Voxia requiere conexión para el reconocimiento de voz.';
      _appendLog(msg);
      return VoxiaResult.failure(msg);
    } on TimeoutException {
      const msg = 'No se pudo verificar la conexión a internet (timeout). Verifica tu red.';
      _appendLog(msg);
      return VoxiaResult.failure(msg);
    } catch (e) {
      // En plataformas donde InternetAddress.lookup no está disponible (e.g., web)
      // continuamos sin verificar.
      _appendLog('No se pudo verificar conectividad: $e');
      return VoxiaResult.success(null);
    }
  }

  Future<VoxiaResult<void>> _checkMicrophonePermission() async {
    try {
      var status = await Permission.microphone.status;

      if (status.isPermanentlyDenied) {
        const msg = 'El permiso de micrófono fue denegado permanentemente. '
            'Habilítalo en la configuración del dispositivo.';
        _appendLog(msg);
        return VoxiaResult.failure(msg);
      }

      if (status.isDenied) {
        status = await Permission.microphone.request();
      }

      if (!status.isGranted) {
        const msg = 'Se requiere permiso de micrófono para usar Voxia.';
        _appendLog(msg);
        return VoxiaResult.failure(msg);
      }

      return VoxiaResult.success(null);
    } catch (e) {
      // En plataformas donde permission_handler no está disponible (e.g., web),
      // continuamos y dejamos que speech_to_text maneje el permiso.
      _appendLog('No se pudo verificar permisos explícitamente: $e');
      return VoxiaResult.success(null);
    }
  }

  Future<void> _initializeTts() async {
    try {
      await _tts.awaitSpeakCompletion(false);

      _tts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _tts.setErrorHandler((message) {
        _isSpeaking = false;
        notifyListeners();
      });

      final List<dynamic>? availableLangs = await _tts.getLanguages;
      final languages =
          availableLangs?.map((l) => l.toString().toLowerCase()).toList() ?? [];

      final String spanish = languages.firstWhere((lang) {
        // Acepta: 'es', 'es-es', 'es_us', 'spa', 'spa-mex', etc.
        return lang.startsWith('es') || lang.startsWith('spa');
      }, orElse: () => '');

      if (spanish.isNotEmpty) {
        await _tts.setLanguage(spanish);
        _appendLog('TTS configurado en: $spanish');
        debugPrint('❗TTS configurado en: $spanish');
      } else {
        await _tts.setLanguage("es-ES");
        _appendLog('Advertencia: No se detectó español, forzando es-ES');
        debugPrint('❗Advertencia: No se detectó español, forzando es-ES');
      }
    } catch (e) {
      _appendLog('Error al inicializar TTS: $e');
      debugPrint('❗Error al inicializar TTS: $e');
      rethrow; // Re-lanza el error para que sea manejado por login()
    }
  }

  //Habilita el reconocimiento de voz, maneja errores y actualiza el estado según la disponibilidad y permisos.
  Future<void> _initializeSpeech() async {
    try {
      final bool available = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: true,
      );

      if (!available) {
        final hasPermission = await _speech.hasPermission;

        _appendLog('Speech not available or permission denied');
        _updateState(
          _state.copyWith(
            speechEnabled: false,
            status: SessionStatus.error,
            lastError:
                'Speech not available or permission denied (Microfono). Has Permission: $hasPermission',
          ),
        );
        return;
      }

      final locales = await _speech.locales();
      final locale = locales.firstWhere(
        (l) => l.localeId.startsWith('es'),
        orElse: () => locales.first,
      );
      debugPrint('😁 LOCALES: ${locales} Locale selected: ${locale.localeId}');

      _updateState(
        _state.copyWith(
          status: SessionStatus.ready,
          speechEnabled: true,
          localeId: locale.localeId,
          lastError: null,
        ),
      );
    } catch (e) {
      _appendLog('Error al inicializar Speech: $e');

      rethrow; // Re-lanza el error para que sea manejado por login()
    }
  }

  /// Reactiva la escucha sin resetear el estado anterior (continuación de sesión)
  Future<void> _reactivateListening() async {
    if (!_state.canListen) {
      return;
    }

    _cancelSilenceTimer();
    _updateState(
      _state.copyWith(
        isListening: true,
        silenceStopPending: false,
        hasSpoken: false,
        lastError: null,
      ),
    );

    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: _listenFor,
      pauseFor: _silenceTimeout,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
      localeId: _state.localeId.isEmpty ? null : _state.localeId,
    );
  }

  // Maneja los resultados del reconocimiento de voz, actualiza el estado con el texto reconocido y controla el temporizador de silencio para detener la escucha automáticamente.
  void _onSpeechResult(SpeechRecognitionResult result) {
    var recognized = result.recognizedWords;

    if (_previousRecognizedText != null &&
        _previousRecognizedText!.isNotEmpty) {
      recognized = '$_previousRecognizedText $recognized';
      debugPrint(
        '📕 CONCATENANDO: "$_previousRecognizedText" "${result.recognizedWords}"',
      );
    }

    _appendLog('Speech result: $recognized');
    _cancelSilenceTimer();
    _updateState(
      _state.copyWith(
        recognizedText: recognized,
        hasSpoken: true,
        silenceStopPending: true,
      ),
    );
    // Detiene la escucha automáticamente después de un período de silencio tras detectar que el usuario ha hablado.
    _silenceTimer = Timer(_silenceTimeout, () async {
      if (!_speech.isListening) return;

      _appendLog('Silence auto-stop after ${_silenceTimeout.inSeconds}s');
      _updateState(_state.copyWith(silenceStopPending: false));
      await _speech.stop();
      _updateState(_state.copyWith(isListening: false));
    });
  }

  void _onStatus(String status) async {
    _appendLog('Speech status: $status');

    if (status == SpeechToText.listeningStatus || status == 'listening') {
      _cancelSilenceTimer();
      _updateState(
        _state.copyWith(isListening: true, silenceStopPending: false),
      );
    } else if (status == SpeechToText.doneStatus || status == 'done') {
      //si el usuario no hablo se detiene la sesión, si hablo se espera el silencio para detenerla automáticamente

      if (!_state.hasSpoken) {
        _appendLog('Stopping: no user speech detected during session');

        await _speech.stop();
        _updateState(
          _state.copyWith(isListening: false, silenceStopPending: false),
        );
      } else {
        _appendLog('Motor nativo cerró, reactivando en 1s...');
        debugPrint(
          '❗ Motor nativo cerró, usuario había hablado, reactivando...',
        );

        // Guardar el texto actual antes de reactivar
        _previousRecognizedText = _state.recognizedText;

        _updateState(
          _state.copyWith(isListening: false, silenceStopPending: false),
        );

        await Future<void>.delayed(const Duration(seconds: 1));

        // Verificar que aún queremos escuchar antes de reactivar
        if (_state.status == SessionStatus.ready && !_forceStop) {
          await _reactivateListening();
        } else if (_forceStop) {}
      }
    }
  }

  void _onError(SpeechRecognitionError errorNotification) {
    _appendLog('Error: ${errorNotification.errorMsg}');

    _updateState(_state.copyWith(lastError: errorNotification.errorMsg));
  }

  void _cancelSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  void _appendLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _logLines.add('$timestamp: $message');
    const maxLogLines = 80;
    if (_logLines.length > maxLogLines) {
      _logLines.removeRange(0, _logLines.length - maxLogLines);
    }
  }

  void _updateState(VoxiaSessionState newState) {
    if (newState == _state) return;
    _state = newState;

    notifyListeners();
  }
}
