import '../../../domain/forms/educacionFamilia/educacion_familia_form_result.dart';
import '../../../domain/forms/educacionFamilia/item_educacion_familia.dart';
import '../../../domain/forms/educacionFamilia/registro_educacion_familia.dart';
import '../flat_slot.dart';
import '../voxia_form_adapter.dart';

/// Adaptador para el formulario de educación a la familia.
///
/// Entrada esperada:
/// ```json
/// {
///   "educacionFamilia": {
///     "items": [ { "codigo", "descripcion", "nombre" } ]
///   }
/// }
/// ```
///
/// Salida: [EducacionFamiliaFormResult] cuyo [toJson] produce la lista
/// compatible con `registroEducacionFamilia` del JSON de salida.
class EducacionFamiliaFormAdapter
    extends VoxiaFormAdapter<EducacionFamiliaFormResult> {
  const EducacionFamiliaFormAdapter();

  @override
  String get formKey => 'educacionFamilia';

  @override
  String get promptRules =>
      '- Para cada campo de educacion responde EXACTAMENTE con "si" si se menciona que se impartio o realizo ese tema, o "no" si no se menciona.\n'
      '- No uses mayusculas ni puntuacion extra en los valores "si" y "no".\n'
      '- Si la transcripción indica de forma general que se impartió toda la educación, educación completa, todos los temas o educación integral, interpreta que TODOS los campos del formulario fueron impartidos y responde "si" en cada uno de ellos.\n'
      '- Para el campo "guion" genera un texto narrativo breve en espanol que resuma los temas de educacion impartidos a la familia segun la transcripcion.';

  @override
  List<FlatSlot> buildSlots(Map<String, dynamic> formJson) {
    final slots = <FlatSlot>[];
    for (final item in _parseItems(formJson)) {
      slots.add(FlatSlot(
        id: item.codigo.toString(),
        label: item.descripcion,
        formatHint: 'si | no',
      ));
    }
    slots.add(const FlatSlot(
      id: 'guion',
      label: 'Resumen de educacion impartida a la familia',
      formatHint: 'texto libre en espanol resumiendo los temas de educacion',
    ));
    return slots;
  }

  @override
  EducacionFamiliaFormResult buildOutput(
    Map<String, dynamic> formJson,
    Map<String, String> answers,
  ) {
    final registros = <RegistroEducacionFamilia>[];
    for (final item in _parseItems(formJson)) {
      final raw = answers[item.codigo.toString()];
      final valor = _sanitize(raw);
      registros.add(RegistroEducacionFamilia(
        nombreId: item.codigo,
        nombre: item.descripcion,
        valorId: valor == 'si' ? 11 : 12,
        valor: valor,
      ));
    }
    final guion = answers['guion']?.trim() ?? '';
    if (guion.isNotEmpty) {
      registros.add(RegistroEducacionFamilia(
        nombreId: null,
        nombre: 'guion',
        valorId: null,
        valor: guion,
      ));
    }
    return EducacionFamiliaFormResult(registros: registros);
  }

  List<ItemEducacionFamilia> _parseItems(Map<String, dynamic> formJson) {
    final data = formJson['educacionFamilia'] as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>;
    return list
        .map((e) => ItemEducacionFamilia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _sanitize(String? raw) {
    if (raw == null) return 'no';
    final v = raw.trim().toLowerCase();
    return (v == 'si') ? 'si' : 'no';
  }
}

