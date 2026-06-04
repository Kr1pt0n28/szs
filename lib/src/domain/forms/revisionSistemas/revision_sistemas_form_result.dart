import '../../../domain/entities/voxia_form_output.dart';
import 'registro_revision_sistema.dart';

/// Resultado del formulario de revisión por sistemas listo para serializar
/// en el campo `registroRevisionSistemas` del JSON de salida.
class RevisionSistemasFormResult implements VoxiaFormOutput {
  const RevisionSistemasFormResult({required this.registros});

  final List<RegistroRevisionSistema> registros;

  @override
  List<Map<String, dynamic>> toJson() =>
      registros.map((r) => r.toJson()).toList();
}
