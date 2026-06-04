import '../../../domain/entities/voxia_form_output.dart';
import 'registro_signo_vital.dart';

/// Resultado del formulario de signos vitales listo para serializar
/// en el campo `registroSignosVitales` del JSON de salida.
class SignosVitalesFormResult implements VoxiaFormOutput {
  const SignosVitalesFormResult({required this.registros});

  final List<RegistroSignoVital> registros;

  @override
  List<Map<String, dynamic>> toJson() =>
      registros.map((r) => r.toJson()).toList();
}
