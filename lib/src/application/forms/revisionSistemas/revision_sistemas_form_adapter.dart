import '../../../domain/forms/revisionSistemas/registro_revision_sistema.dart';
import '../../../domain/forms/revisionSistemas/revision_sistemas_form_result.dart';
import '../../../domain/forms/revisionSistemas/seccion_revision_sistema.dart';
import '../flat_slot.dart';
import '../voxia_form_adapter.dart';

/// Adaptador para el formulario de revisión por sistemas.
///
/// Entrada esperada:
/// ```json
/// {
///   "revisionSistemas": [
///     { "nombre", "descripcion", "items": [ { "nombre", "descripcion", "codigo" } ] }
///   ]
/// }
/// ```
///
/// Cada ítem se convierte en un slot con tres valores posibles.
/// Adicionalmente se incluye un slot "guion" para la narrativa libre.
///
/// Salida: [RevisionSistemasFormResult] cuyo [toJson] produce la lista
/// compatible con `registroRevisionSistemas` del JSON de salida.
class RevisionSistemasFormAdapter
    extends VoxiaFormAdapter<RevisionSistemasFormResult> {
  const RevisionSistemasFormAdapter();

  @override
  String get formKey => 'revisionSistemas';

  @override
  String get promptRules =>
      '- El campo "label" tiene el formato "Sección — Pregunta": la parte antes del " — " es la sección del formulario y la parte después es el síntoma o hallazgo clínico específico que debes evaluar.\n'
      '- Para cada campo, si se menciona en la transcripción responde EXACTAMENTE con uno de: "refiere", "no refiere" o "no aplica".\n'
      '- Si el campo NO se menciona ni se puede inferir de la transcripción, usa "no aplica" como respuesta.\n'
      '- No uses mayúsculas, acentos ni puntuación extra en los tres valores nombrados.\n'
      '- Para el campo "guion" genera un texto narrativo corto en español que resuma los hallazgos clínicos relevantes mencionados en la transcripción.';

  @override
  List<FlatSlot> buildSlots(Map<String, dynamic> formJson) {
    final slots = <FlatSlot>[];
    for (final seccion in _parseSecciones(formJson)) {
      for (final item in seccion.items) {
        slots.add(FlatSlot(
          id: item.codigo.toString(),
          label: '${seccion.descripcion} — ${item.descripcion}',
          formatHint: 'refiere | no refiere | no aplica',
        ));
      }
    }
    slots.add(const FlatSlot(
      id: 'guion',
      label: 'Resumen narrativo',
      formatHint: 'texto libre en español resumiendo los hallazgos clínicos',
    ));
    return slots;
  }

  @override
  RevisionSistemasFormResult buildOutput(
    Map<String, dynamic> formJson,
    Map<String, String> answers,
  ) {
    final registros = <RegistroRevisionSistema>[];

    for (final seccion in _parseSecciones(formJson)) {
      for (final item in seccion.items) {
        final raw = answers[item.codigo.toString()];
        final valor = _sanitizeValor(raw);
        registros.add(RegistroRevisionSistema(
          conceptoId: item.codigo,
          nombre: item.nombre,
          valor: valor,
        ));
      }
    }

    // Guion narrativo al final
    final guion = answers['guion']?.trim() ?? '';
    if (guion.isNotEmpty) {
      registros.add(RegistroRevisionSistema(
        conceptoId: null,
        nombre: 'guion',
        valor: guion,
      ));
    }

    return RevisionSistemasFormResult(registros: registros);
  }

  List<SeccionRevisionSistema> _parseSecciones(
      Map<String, dynamic> formJson) {
    final list = formJson['revisionSistemas'] as List<dynamic>;
    return list
        .map((e) =>
            SeccionRevisionSistema.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Normaliza la respuesta de la IA a uno de los tres valores válidos.
  /// Retorna 'no aplica' si el campo no fue mencionado o el valor no es reconocido.
  String _sanitizeValor(String? raw) {
    if (raw == null) return 'no aplica';
    final v = raw.trim().toLowerCase();
    if (v == 'refiere') return 'refiere';
    if (v == 'no refiere') return 'no refiere';
    return 'no aplica';
  }
}
