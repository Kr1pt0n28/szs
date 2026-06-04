import 'package:flutter/foundation.dart';

import '../../domain/entities/voxia_result.dart';
import '../../infrastructure/config/voxia_config.dart';
import '../forms/form_adapter_registry.dart';
import '../model/foundry.dart';
import 'fill.dart';

class VoxiaFormController {
  const VoxiaFormController();

  /// Procesa un formulario JSON con IA y retorna [VoxiaFormSuccess] con:
  /// - [VoxiaFormSuccess.rawData]: mapa campoId → valor para rellenar los widgets.
  /// - [VoxiaFormSuccess.completedJson]: snapshot serializado del formulario.
  ///
  /// Detecta automáticamente el tipo de formulario inspeccionando las claves del JSON.
  Future<VoxiaResult<Map<String, String>>> processJson({
    required Map<String, dynamic> formJson,
    required String transcription,
    String modelFileName = 'gpt-4.1-mini',
  }) async {

    debugPrint('🐯🐯 PROCESAR FORMULARIO: $formJson');
    final adapter = FormAdapterRegistry.detectAdapter(formJson);

    debugPrint('🐯 - Adaptador: $adapter');

    if (adapter == null) {
      return VoxiaResult.failure(
        'Tipo de formulario no reconocido. Claves presentes: ${formJson.keys.join(", ")}',
      );
    }

    final slots = adapter.buildSlots(formJson);
    if (slots.isEmpty) {
      return VoxiaResult.failure('El formulario no tiene campos para procesar.');
    }

    debugPrint('🐯 - Formulario con: ${slots.length} campos, modelo $modelFileName...');

    final llm = FoundryService(
      model: modelFileName,
      endpoint: VoxiaConfig.azureFoundryEndpoint,
      apiKey: VoxiaConfig.azureFoundryApiKey,
    );
    final fill = Fill(
      llm: llm,
      systemPrompt: VoxiaConfig.systemPrompt,
    );
    final Map<String, String> answers;
    try {
      answers = await fill.fillFromTranscription(
        slots: slots,
        transcription: transcription,
        promptRules: adapter.promptRules,
      );
    } catch (e) {
      return VoxiaResult.failure(_describeError(e));
    }

    debugPrint('🐯 LLM: listo ✅ (${answers.length} respuestas)');

    final completedJson = adapter.buildOutput(formJson, answers);
    return VoxiaFormSuccess(rawData: answers, completedJson: completedJson);
  }

  String _describeError(Object e) {
    final msg = e.toString();
    if (msg.contains('Sin conexión') || msg.contains('SocketException')) {
      return 'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.';
    }
    if (msg.contains('Tiempo de espera') || msg.contains('TimeoutException')) {
      return 'Tiempo de espera agotado. Verifica tu conexión e inténtalo de nuevo.';
    }
    if (msg.contains('inválida') || msg.contains('403') || msg.contains('401')) {
      return 'Clave de API inválida o sin permisos. Revisa la configuración de VoxiaConfig.';
    }
    return 'Error al procesar con el modelo: $msg';
  }
}


