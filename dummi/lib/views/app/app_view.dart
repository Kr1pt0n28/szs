import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sura_voxia/sura_voxia.dart';

import 'educacion_familia_form.dart';
import 'revision_sistemas_form.dart';
import 'signos_vitales_form.dart';
import 'sura_colors.dart';

class AppView extends StatefulWidget {
  const AppView({super.key, required this.controller});

  final VoxiaController controller;

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  VoxiaController get _controller => widget.controller;

  // IA processing state
  bool _isProcessing = false;
  String _selectedModel = 'gpt-4.1-mini';
  static const List<String> _models = [
    'gpt-4.1-mini',
  ];

  // JSON cargado desde assets/jsonEntrada.json
  Map<String, dynamic>? _jsonData;
  List<Map<String, dynamic>> _vitals = [];
  List<Map<String, dynamic>> _revisionSecciones = [];
  List<Map<String, dynamic>> _educacionItems = [];
  bool _jsonLoaded = false;

  // Sidebar
  int _selectedSidebarIndex = 0;

  // Revisión por sistemas: Map<codigo.toString() | 'guion', valor>
  Map<String, String> _revisionAnswers = {};

  // Educación a la familia: Map<codigo.toString(), bool>
  Map<String, bool> _educacionToggles = {};

  // Controladores de texto keyed por campoId (coincide con el backend)
  final Map<String, TextEditingController> _fieldControllers = {};

  // Controlador del guion narrativo (revisión por sistemas)
  final TextEditingController _guionController = TextEditingController();

  // Controlador del guion narrativo (educación a la familia)
  final TextEditingController _guionEducacionController = TextEditingController();

  // Controlador de la transcripción — editable manualmente o actualizado por voz
  final TextEditingController _transcriptController = TextEditingController();

  // Resultado IA más reciente — null si no hay análisis IA
  VoxiaFormSuccess? _lastAiSuccess;
  // true si el formulario fue editado manualmente tras el último análisis IA
  bool _formModifiedAfterAi = false;

  String? _displayedError;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onVoiceUpdate);
    _loadJsonEntrada();
  }

  static Map<String, dynamic> _decodeJson(String raw) =>
      jsonDecode(raw) as Map<String, dynamic>;

  Future<void> _loadJsonEntrada() async {
    try {
      final raw = await rootBundle.loadString('assets/jsonEntrada.json');
      final decoded = await compute(_decodeJson, raw);
      final vitals = (decoded['signosVitales']['listaSignosVitales'] as List)
          .cast<Map<String, dynamic>>();
      final controllers = <String, TextEditingController>{};
      for (final v in vitals) {
        controllers[v['campoId'].toString()] = TextEditingController();
      }
      final educItems = (decoded['educacionFamilia']['items'] as List)
          .cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _jsonData = decoded;
          _vitals = vitals;
          _revisionSecciones = (decoded['revisionSistemas'] as List)
              .cast<Map<String, dynamic>>();
          _educacionItems = educItems;
          _fieldControllers.addAll(controllers);
          _jsonLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _displayedError = 'Error cargando formulario: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVoiceUpdate);
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    _guionController.dispose();
    _guionEducacionController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  void _onVoiceUpdate() {
    if (!mounted) return;
    final voiceText = _controller.state.recognizedText;
    if (_transcriptController.text != voiceText) {
      _transcriptController.text = voiceText;
    }
    setState(() {});
  }

  Future<void> _handleToggleSession() async {
    final state = _controller.state;
    if (state.status != SessionStatus.loggedOut) {
      await _controller.logout();
      setState(() => _displayedError = null);
    } else {
      setState(() => _displayedError = null);
      await _controller.login();
    }
  }

  Future<void> _handleListeningToggle() async {
    if (_controller.state.isListening) {
      await _controller.stopListening();
    } else {
      await _controller.startListening();
    }
  }

  Future<void> _processWithAI() async {
    if (_isProcessing) return;
    final transcript = _transcriptController.text.trim();
    if (transcript.isEmpty) {
      setState(
        () => _displayedError =
            'Primero graba una transcripción usando el micrófono.',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _displayedError = null;
    });

    try {
      final Map<String, dynamic> formJson;
      if (_selectedSidebarIndex == 1) {
        formJson = {'revisionSistemas': _jsonData!['revisionSistemas']};
      } else if (_selectedSidebarIndex == 2) {
        formJson = {'educacionFamilia': _jsonData!['educacionFamilia']};
      } else {
        formJson = {'signosVitales': _jsonData!['signosVitales']};
      }

      final result = await VoxiaFormController().processJson(
        formJson: formJson,
        transcription: transcript,
        modelFileName: _selectedModel,
      );

      debugPrint('💯- respuesta recibida:\n$result');

      if (result is VoxiaFailure) {
        setState(() {
          _isProcessing = false;
          _displayedError = (result as VoxiaFailure).error;
        });
        return;
      }

      final success = result as VoxiaFormSuccess;

      if (_selectedSidebarIndex == 1) {
        // Llenar radio buttons de revisión por sistemas
        setState(() {
          for (final entry in success.rawData.entries) {
            _revisionAnswers[entry.key] = entry.value;
          }
          _guionController.text = _revisionAnswers['guion'] ?? '';
          _lastAiSuccess = success;
          _formModifiedAfterAi = false;
          _isProcessing = false;
        });
      } else if (_selectedSidebarIndex == 2) {
        // Llenar toggles de educación a la familia
        setState(() {
          for (final entry in success.rawData.entries) {
            if (entry.key == 'guion') {
              _guionEducacionController.text = entry.value;
            } else {
              _educacionToggles[entry.key] = entry.value == 'si';
            }
          }
          _lastAiSuccess = success;
          _formModifiedAfterAi = false;
          _isProcessing = false;
        });
      } else {
        // Llenar inputs de signos vitales
        for (final entry in success.rawData.entries) {
          _fieldControllers[entry.key]?.text = entry.value;
        }
        setState(() {
          _lastAiSuccess = success;
          _formModifiedAfterAi = false;
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _displayedError = 'Error inesperado: $e';
      });
    }
  }

  void _clearAll() {
    for (final c in _fieldControllers.values) {
      c.text = '';
    }
    _guionController.text = '';
    _guionEducacionController.text = '';
    _transcriptController.text = '';
    setState(() {
      _revisionAnswers = {};
      _educacionToggles = {};
      _lastAiSuccess = null;
      _formModifiedAfterAi = false;
      _displayedError = null;
    });
    _controller.clearRecognizedText();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = _controller.state;
    final isLoggedIn = voiceState.status != SessionStatus.loggedOut;
    final isListening = voiceState.isListening;

    final voiceError = voiceState.lastError;
    if (voiceError != null &&
        voiceError.isNotEmpty &&
        _displayedError == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _displayedError = voiceError),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          _buildHeader(voiceState, isLoggedIn, isListening),
          if (_displayedError != null && _displayedError!.isNotEmpty)
            _buildErrorBanner(_displayedError!),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSidebar(),
                Expanded(
                  child: !_jsonLoaded
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Mic + section title row
                              Row(
                                children: [
                                  _buildMicButton(isLoggedIn, isListening),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Captura de voz',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF444444),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTranscriptCard(),

                              const SizedBox(height: 24),

                              const Text(
                                'Análisis con IA',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF444444),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildModelSelector(),
                              const SizedBox(height: 12),
                              _buildAnalyzeButton(),

                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Formulario',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF444444),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _clearAll,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Limpiar'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_selectedSidebarIndex == 2)
                                EducacionFamiliaForm(
                                  items: _educacionItems,
                                  toggles: _educacionToggles,
                                  onToggle: (codigo, val) {
                                    setState(() {
                                      _educacionToggles[codigo] = val;
                                      if (_lastAiSuccess != null) _formModifiedAfterAi = true;
                                    });
                                  },
                                )
                              else if (_selectedSidebarIndex == 1)
                                RevisionSistemasForm(
                                  secciones: _revisionSecciones,
                                  answers: _revisionAnswers,
                                  onAnswerChanged: (codigo, valor) {
                                    setState(() {
                                      if (valor == null) {
                                        _revisionAnswers.remove(codigo);
                                      } else {
                                        _revisionAnswers[codigo] = valor;
                                      }
                                      if (_lastAiSuccess != null) _formModifiedAfterAi = true;
                                    });
                                  },
                                )
                              else
                                SignosVitalesForm(
                                  vitals: _vitals,
                                  fieldControllers: _fieldControllers,
                                  onFieldChanged: () => setState(() {
                                    if (_lastAiSuccess != null) _formModifiedAfterAi = true;
                                  }),
                                ),
                              if (_selectedSidebarIndex == 1) ...[const SizedBox(height: 16), _buildGuionCard()],
                              if (_selectedSidebarIndex == 2) ...[const SizedBox(height: 16), _buildGuionEducacionCard()],
                              const SizedBox(height: 24),
                              _buildSubmitButton(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    VoxiaSessionState state,
    bool isLoggedIn,
    bool isListening,
  ) {
    return Container(
      padding: const EdgeInsets.only(top: 56, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kAzulSura, kAzulVivo],
        ),
        // borderRadius: BorderRadius.only(
        //   bottomLeft: Radius.circular(28),
        //   bottomRight: Radius.circular(28),
        // ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sura Voxia App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.speechEnabled ? kVerdeExito : kRojoError,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.speechEnabled ? 'Micrófono listo' : 'Sin sesión',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                    if (isListening) ...[
                      const SizedBox(width: 10),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Escuchando...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _handleToggleSession,
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              radius: 20,
              child: Icon(
                isLoggedIn ? Icons.logout : Icons.login,
                color: kAmarilloAlegre,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar
  // ---------------------------------------------------------------------------

  static const List<({String label, IconData icon})> _sidebarItems = [
    (label: 'Signos vitales', icon: Icons.monitor_heart_outlined),
    (label: 'Revisión por sistemas', icon: Icons.assignment_outlined),
    (label: 'Educación familia', icon: Icons.family_restroom_outlined),
  ];

  Widget _buildSidebar() {
    return Container(
      width: 120,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < _sidebarItems.length; i++) _buildSidebarItem(i),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index) {
    final item = _sidebarItems[index];
    final isActive = _selectedSidebarIndex == index;
    return InkWell(
      onTap: () => setState(() {
        _selectedSidebarIndex = index;
        _transcriptController.text = '';
        _controller.clearRecognizedText();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? kAzulSura : Colors.transparent,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          border: Border(
            left: BorderSide(
              color: isActive ? kAquaSura : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 15,
              color: isActive ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kRojoError.withValues(alpha: 0.08),
        border: Border.all(color: kRojoError.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: kRojoError, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: kRojoError, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _displayedError = null),
            child: const Icon(Icons.close, color: kRojoError, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(bool isLoggedIn, bool isListening) {
    return GestureDetector(
      onTap: isLoggedIn ? _handleListeningToggle : _handleToggleSession,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: !isLoggedIn
              ? Colors.grey[400]
              : (isListening ? kRojoError : kAquaSura),
          boxShadow: [
            BoxShadow(
              color: (isListening ? kRojoError : kAquaSura).withValues(
                alpha: 0.3,
              ),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          isListening ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildGuionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAzulSura.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article_outlined, size: 14, color: kAzulSura),
              const SizedBox(width: 6),
              const Text(
                'Guion narrativo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _guionController,
            maxLines: null,
            minLines: 3,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'El resumen narrativo generado por la IA aparecerá aquí…',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kAzulSura.withValues(alpha: 0.5)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (val) {
              setState(() {
                if (val.trim().isEmpty) {
                  _revisionAnswers.remove('guion');
                } else {
                  _revisionAnswers['guion'] = val;
                }
                if (_lastAiSuccess != null) _formModifiedAfterAi = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuionEducacionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAzulSura.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article_outlined, size: 14, color: kAzulSura),
              const SizedBox(width: 6),
              const Text(
                'Guión de educación',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _guionEducacionController,
            maxLines: null,
            minLines: 3,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'El resumen de educación generado por la IA aparecerá aquí…',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kAzulSura.withValues(alpha: 0.5)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (_) => setState(() {
              if (_lastAiSuccess != null) _formModifiedAfterAi = true;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAzulSura.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Transcripción',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _transcriptController.text = '';
                  _controller.clearRecognizedText();
                },
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Borrar transcripción',
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _transcriptController,
            maxLines: null,
            minLines: 3,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Dicta con el micrófono o escribe aquí…',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kAzulSura.withValues(alpha: 0.5)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedModel,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: kAzulSura),
          items: _models
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(
                    m,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedModel = v!),
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return ElevatedButton.icon(
      onPressed: (_isProcessing || !_jsonLoaded) ? null : _processWithAI,
      style: ElevatedButton.styleFrom(
        backgroundColor: kAzulSura,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        disabledBackgroundColor: kAzulSura.withValues(alpha: 0.5),
      ),
      icon: _isProcessing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.auto_awesome, size: 18),
      label: Text(_isProcessing ? 'Analizando...' : 'Analizar con IA'),
    );
  }

  Widget _buildSubmitButton() {
    final hasResult = _lastAiSuccess != null;
    if (!hasResult) return const SizedBox.shrink();
    return ElevatedButton.icon(
      onPressed: _buildAndShowResult,
      style: ElevatedButton.styleFrom(
        backgroundColor: kVerdeExito,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.auto_awesome, size: 18),
      label: const Text('Ver respuesta IA'),
    );
  }

  void _buildAndShowResult() {
    final success = _lastAiSuccess!;
    final wasModified = _formModifiedAfterAi;
    final prettyCompleted = const JsonEncoder.withIndent('  ').convert(
      success.completedJson.toJson(),
    );
    final prettyRaw = const JsonEncoder.withIndent('  ').convert(
      success.rawData,
    );

    final String countLabel;
    if (_selectedSidebarIndex == 2) {
      final total = _educacionItems.length;
      final activated = success.rawData.values.where((v) => v == 'si').length;
      countLabel = '$activated / $total temas activados';
    } else if (_selectedSidebarIndex == 1) {
      final totalItems = _revisionSecciones.fold<int>(
        0,
        (sum, s) => sum + (s['items'] as List).length,
      );
      final answered = success.rawData.keys.where((k) => k != 'guion').length;
      countLabel = '$answered / $totalItems ítems completados';
    } else {
      countLabel = '${success.rawData.length} / ${_vitals.length} campos completados';
    }

    showDialog(
      context: context,
      builder: (_) => DefaultTabController(
        length: 2,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: kVerdeExito, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Respuesta IA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kAzulSura,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  countLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (wasModified) ...[  
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      border: Border.all(color: const Color(0xFFFFCC00)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Color(0xFF856404)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Este es el último resultado de IA y no refleja los cambios manuales realizados después.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF856404)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TabBar(
                  labelColor: kAzulSura,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: kAzulSura,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'JSON salida'),
                    Tab(text: 'Raw IA'),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildJsonBlock(prettyCompleted),
                      _buildJsonBlock(prettyRaw),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(color: kAzulSura),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJsonBlock(String json) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          json,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Color(0xFFCDD6F4),
          ),
        ),
      ),
    );
  }
}
