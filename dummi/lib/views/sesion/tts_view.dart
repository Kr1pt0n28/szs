import 'package:flutter/material.dart';
import 'package:sura_voxia/sura_voxia.dart';

class TtsView extends StatefulWidget {
  const TtsView({super.key, required this.controller});

  final VoxiaController controller;

  @override
  State<TtsView> createState() => _TtsViewState();
}

class _TtsViewState extends State<TtsView> {
  // Colores Corporativos SURA
  static const Color azulSura = Color.fromRGBO(0, 51, 160, 1);
  static const Color aquaSura = Color.fromRGBO(0, 174, 199, 1);
  static const Color amarilloAlegre = Color.fromRGBO(255, 233, 70, 1);
  static const Color azulVivo = Color.fromRGBO(78, 195, 224, 1);
  static const Color verdeExito = Color.fromRGBO(197, 232, 108, 1);
  static const Color rojoError = Color.fromRGBO(228, 0, 43, 1);

  VoxiaController get _controller => widget.controller;

  // Track the last displayed error to avoid duplicate renders
  String? _displayedError;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _handleSessionToggle() async {
    final state = _controller.state;
    if (state.status != SessionStatus.loggedOut) {
      await _controller.logout();
      if (mounted) setState(() => _displayedError = null);
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

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final isLoggedIn = state.status != SessionStatus.loggedOut;
    final isListening = state.isListening;
    final hasText = state.recognizedText.isNotEmpty;

    // Sync displayed error with latest from state
    final currentError = state.lastError;
    if (currentError != null && currentError.isNotEmpty) {
      _displayedError = currentError;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          _buildIntegratedHeader(state, isLoggedIn),
          if (_displayedError != null && _displayedError!.isNotEmpty)
            _buildErrorBanner(_displayedError!),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildMicrophoneButton(isLoggedIn, isListening),
                  const SizedBox(height: 40),
                  _buildMessageBubble(state.recognizedText, hasText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rojoError.withValues(alpha: 0.08),
        border: Border.all(color: rojoError.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: rojoError, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: rojoError, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _displayedError = null),
            child: const Icon(Icons.close, color: rojoError, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegratedHeader(VoxiaSessionState state, bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [azulSura, azulVivo],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🐯 SURA VoxIA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: _handleSessionToggle,
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  radius: 20,
                  child: Icon(
                    isLoggedIn ? Icons.login : Icons.person,
                    color: amarilloAlegre,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.speechEnabled ? verdeExito : rojoError,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                state.speechEnabled
                    ? 'Micrófono Listo'
                    : 'Sin Permisos (Inicia Sesión Primero)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (state.status == SessionStatus.initializing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Iniciando sesión...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool hasText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: azulSura.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasText ? text : 'Presiona el micrófono y cuéntanos...',
            style: TextStyle(
              fontSize: 16,
              color: hasText ? Colors.black87 : Colors.grey[400],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 22, color: rojoError),
                onPressed: _controller.clearRecognizedText,
              ),
              const Spacer(),
              if (hasText)
                GestureDetector(
                  onTap: _controller.isSpeaking
                      ? () => _controller.stopSpeak()
                      : () => _controller.speakText(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _controller.isSpeaking
                          ? Colors.red.withValues(alpha: 0.1)
                          : aquaSura.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _controller.isSpeaking
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: _controller.isSpeaking ? Colors.red : aquaSura,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _controller.isSpeaking ? 'Detener' : 'Escuchar',
                          style: TextStyle(
                            color: _controller.isSpeaking
                                ? Colors.red
                                : aquaSura,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMicrophoneButton(bool isLoggedIn, bool isListening) {
    return Column(
      children: [
        GestureDetector(
          onTap: isLoggedIn ? _handleListeningToggle : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: !isLoggedIn
                  ? Colors.grey[400]
                  : (isListening ? rojoError : aquaSura),
              boxShadow: isListening
                  ? [
                      BoxShadow(
                        color: rojoError.withValues(alpha: 0.3),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: aquaSura.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Icon(
              isListening ? Icons.stop_rounded : Icons.mic_rounded,
              size: 45,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          isListening ? 'DETENER' : 'HABLAR',
          style: TextStyle(
            color: isLoggedIn
                ? (isListening ? rojoError : azulSura)
                : Colors.grey,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
