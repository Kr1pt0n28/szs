/// Representa un campo del formulario aplanado en una lista plana para el prompt de IA.
class FlatSlot {
  const FlatSlot({
    required this.id,
    required this.label,
    required this.formatHint,
  });

  /// Identificador único del campo. Debe coincidir con el backend (ej. campoId).
  final String id;

  /// Etiqueta legible para el LLM (ej. "Presión Arterial Sistólica").
  final String label;

  /// Indicación del formato/rango esperado (ej. "número entre 0.0 y 200.0 (mm Hg)").
  final String formatHint;
}
