import '../../../domain/forms/signosVitales/registro_signo_vital.dart';
import '../../../domain/forms/signosVitales/signo_vital.dart';
import '../../../domain/forms/signosVitales/signosVitales_form_result.dart';
import '../flat_slot.dart';
import '../voxia_form_adapter.dart';

/// Adaptador para el formulario de signos vitales.
///
/// Entrada esperada:
/// ```json
/// {
///   "signosVitales": {
///     "listaSignosVitales": [ { "descripcion", "unidad", "nombre",
///                               "minimo", "maximo", "campoId", "tipoDato" } ]
///   }
/// }
/// ```
///
/// Salida: [SignosVitalesFormResult] cuyo [toJson] produce la lista
/// compatible con `registroSignosVitales` del JSON de salida.
class SignosVitalesFormAdapter
    extends VoxiaFormAdapter<SignosVitalesFormResult> {
  const SignosVitalesFormAdapter();

  @override
  String get formKey => 'signosVitales';

  @override
  String get promptRules =>
      '- Cada respuesta debe ser un número decimal (ej. "120.0").\n'
      '- Respeta el rango indicado en "format" de cada campo.\n'
      '- Si el valor no se menciona en la transcripción, usa null.';

  @override
  List<FlatSlot> buildSlots(Map<String, dynamic> formJson) {
    return _parseVitals(formJson).map((v) {
      final range = 'número entre ${v.minimo} y ${v.maximo}'
          '${v.unidad != null ? ' (${v.unidad})' : ''}';
      return FlatSlot(
        id: v.campoId.toString(),
        label: v.descripcion,
        formatHint: range,
      );
    }).toList();
  }

  @override
  SignosVitalesFormResult buildOutput(
    Map<String, dynamic> formJson,
    Map<String, String> answers,
  ) {
    final vitals = _parseVitals(formJson);
    final registros = vitals.map((v) {
      final raw = answers[v.campoId.toString()];
      final valor = raw != null ? (double.tryParse(raw) ?? -1.0) : -1.0;
      return RegistroSignoVital(
        nombre: v.nombre,
        valor: valor,
        campoId: v.campoId,
        tipoDato: v.tipoDato,
        unidad: v.unidad,
      );
    }).toList();
    return SignosVitalesFormResult(registros: registros);
  }

  List<SignoVital> _parseVitals(Map<String, dynamic> formJson) {
    final data = formJson['signosVitales'] as Map<String, dynamic>;
    final list = data['listaSignosVitales'] as List<dynamic>;
    return list
        .map((e) => SignoVital.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

