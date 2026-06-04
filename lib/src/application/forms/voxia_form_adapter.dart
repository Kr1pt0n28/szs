import 'flat_slot.dart';
import '../../domain/entities/voxia_form_output.dart';

/// Contrato que cada tipo de formulario debe implementar.
///
/// [TOutput] es el tipo de resultado específico del formulario
/// (ej. [SignosVitalesFormResult]).
abstract class VoxiaFormAdapter<TOutput extends VoxiaFormOutput> {
  const VoxiaFormAdapter();

  /// Clave top-level que identifica este formulario en el JSON de entrada.
  /// Ej: 'signosVitales'. Se usa para auto-detectar el adaptador correcto.
  String get formKey;

  /// Construye la lista plana de slots que se envían al prompt de IA.
  /// Cada slot representa un campo a rellenar.
  List<FlatSlot> buildSlots(Map<String, dynamic> formJson);

  /// Reglas específicas de este formulario que se inyectan al final del prompt.
  String get promptRules;

  /// Construye el objeto de salida a partir de las respuestas de la IA.
  /// [answers] es un Map de slot id → respuesta (texto crudo de la IA).
  TOutput buildOutput(Map<String, dynamic> formJson, Map<String, String> answers);
}

