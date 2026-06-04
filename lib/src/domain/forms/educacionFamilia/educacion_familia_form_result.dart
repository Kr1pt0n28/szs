import '../../../domain/entities/voxia_form_output.dart';
import 'registro_educacion_familia.dart';

/// Resultado del formulario de educación a la familia listo para serializar
/// en el campo `registroEducacionFamilia` del JSON de salida.
class EducacionFamiliaFormResult implements VoxiaFormOutput {
  const EducacionFamiliaFormResult({required this.registros});

  final List<RegistroEducacionFamilia> registros;

  @override
  List<Map<String, dynamic>> toJson() =>
      registros.map((r) => r.toJson()).toList();
}

