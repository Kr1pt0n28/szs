enum SessionStatus { loggedOut, initializing, ready, error }

// Más simple que voice_state. Estado solo de captura de voz, sin campos relacionados a generación o reproducción de voz.
class VoxiaSessionState {
  const VoxiaSessionState({
    required this.status,
    required this.speechEnabled,
    required this.isListening,
    required this.silenceStopPending,
    required this.hasSpoken,
    required this.localeId,
    required this.recognizedText,
    this.lastError,
  });

  //Estado inicial de la sesión, con valores predeterminados para cada campo.
  factory VoxiaSessionState.initial() {
    return const VoxiaSessionState(
      status: SessionStatus.loggedOut,
      speechEnabled: false,
      isListening: false,
      silenceStopPending: false,
      hasSpoken: false,
      localeId: '',
      recognizedText: '',
      lastError: null,
    );
  }

  final SessionStatus status;
  final bool speechEnabled;
  final bool isListening;
  final bool silenceStopPending;
  final bool hasSpoken;
  final String localeId;
  final String recognizedText;
  final String? lastError;

  bool get canListen => status == SessionStatus.ready && speechEnabled;

  @override
  String toString() {
    return '''
      VoxiaSessionState(
        status: $status,
        speechEnabled: $speechEnabled,
        isListening: $isListening,
        silenceStopPending: $silenceStopPending,
        hasSpoken: $hasSpoken,
        localeId: $localeId,
        recognizedText: $recognizedText,
        lastError: $lastError,
        canListen: $canListen
      )''';
  }

  // Método para crear una nueva instancia de VoxiaSessionState con algunos campos actualizados, manteniendo los demás sin cambios.
  VoxiaSessionState copyWith({
    SessionStatus? status,
    bool? speechEnabled,
    bool? isListening,
    bool? silenceStopPending,
    bool? hasSpoken,
    String? localeId,
    String? recognizedText,
    String? lastError,
  }) {
    return VoxiaSessionState(
      status: status ?? this.status,
      speechEnabled: speechEnabled ?? this.speechEnabled,
      isListening: isListening ?? this.isListening,
      silenceStopPending: silenceStopPending ?? this.silenceStopPending,
      hasSpoken: hasSpoken ?? this.hasSpoken,
      localeId: localeId ?? this.localeId,
      recognizedText: recognizedText ?? this.recognizedText,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoxiaSessionState &&
        other.status == status &&
        other.speechEnabled == speechEnabled &&
        other.isListening == isListening &&
        other.silenceStopPending == silenceStopPending &&
        other.hasSpoken == hasSpoken &&
        other.localeId == localeId &&
        other.recognizedText == recognizedText &&
        other.lastError == lastError;
  }

  @override
  int get hashCode => Object.hash(
    status,
    speechEnabled,
    isListening,
    silenceStopPending,
    hasSpoken,
    localeId,
    recognizedText,
    lastError,
  );
}
