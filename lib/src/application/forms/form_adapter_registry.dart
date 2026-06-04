import '../../domain/entities/voxia_form_output.dart';
import '../../domain/forms/voxia_form_type.dart';
import 'educacionFamilia/educacion_familia_form_adapter.dart';
import 'revisionSistemas/revision_sistemas_form_adapter.dart';
import 'signosVitales/signosVitales_form_adapter.dart';
import 'voxia_form_adapter.dart';

/// Registro central de adaptadores de formulario.
class FormAdapterRegistry {
  const FormAdapterRegistry._();

  static VoxiaFormAdapter<dynamic> forType(VoxiaFormType type) {
    switch (type) {
      case VoxiaFormType.signosVitales:
        return const SignosVitalesFormAdapter();
      case VoxiaFormType.revisionSistemas:
        return const RevisionSistemasFormAdapter();
      case VoxiaFormType.educacionFamilia:
        return const EducacionFamiliaFormAdapter();
    }
  }

  /// Detecta el adaptador correcto inspeccionando las claves top-level del JSON.
  static VoxiaFormAdapter<dynamic>? detectAdapter(
    Map<String, dynamic> formJson,
  ) {
    if (formJson.containsKey('signosVitales')) {
      return const SignosVitalesFormAdapter();
    }
    if (formJson.containsKey('revisionSistemas')) {
      return const RevisionSistemasFormAdapter();
    }
    if (formJson.containsKey('educacionFamilia')) {
      return const EducacionFamiliaFormAdapter();
    }
    return null;
  }

  /// Construye el output del formulario detectando el tipo automáticamente.
  /// Uso interno — llamado por [VoxiaFormController.processJson].
  static VoxiaFormOutput? buildOutput(
    Map<String, dynamic> formJson,
    Map<String, String> answers,
  ) {
    return detectAdapter(formJson)?.buildOutput(formJson, answers);
  }
}


