import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'llm_provider.dart';

class FoundryService implements LlmProvider {
  final String model;
  final String endpoint;
  final String apiKey;

  static const Map<String, Map<String, double>> modelPricing = {
    'gpt-4.1-mini': {'input': 0.44, 'output': 1.76},
  };

  FoundryService({
    required this.model,
    required this.endpoint,
    required this.apiKey,
  });

  @override
  Future<String> generate(String texto, {String? systemPrompt}) async {
    debugPrint("🚀 [Foundry] generate() iniciado con modelo: $model");

    final url = Uri.parse(endpoint);

    final body = {
      "model": model,
      "max_completion_tokens": 10000,
      "temperature": 0,
      "top_p": 1,
      "stop": [],
      "messages": [
        if (systemPrompt != null) {"role": "system", "content": systemPrompt},
        {"role": "user", "content": texto},
      ],
    };

    debugPrint("📡 [Foundry] Enviando request HTTP a ${Uri.parse(endpoint).host}...");

    final http.Response response;
    try {
      response = await http
          .post(
            url,
            headers: {
              "api-key": apiKey,
              "Content-Type": "application/json",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
    } on SocketException catch (e) {
      throw Exception(
        'Sin conexión a internet. Verifica tu red e inténtalo de nuevo. ($e)',
      );
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado al comunicarse con Azure AI Foundry. Verifica tu conexión.',
      );
    }

    debugPrint("📊 [Foundry] Status code: ${response.statusCode}");

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(
        'Clave de API de Azure AI Foundry inválida o sin permisos (HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Error al comunicarse con Azure AI Foundry (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final choices = data["choices"] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Azure AI Foundry no retornó choices en la respuesta.');
    }

    final text = choices[0]["message"]["content"] as String? ?? '';

    if (data["usage"] != null) {
      final usage = data["usage"] as Map<String, dynamic>;
      final promptTokens = usage["prompt_tokens"] ?? 0;
      final completionTokens = usage["completion_tokens"] ?? 0;
      final totalTokens = usage["total_tokens"] ?? 0;
      final cost = _calculateRequestCost(
        promptTokens as int,
        completionTokens as int,
      );
      debugPrint("📊 ========== USO - $model ==========");
      debugPrint("📥 Input tokens: $promptTokens");
      debugPrint("📤 Output tokens: $completionTokens");
      debugPrint("🔢 Total tokens: $totalTokens");
      debugPrint("💰 Costo de esta petición: \$${cost.toStringAsFixed(6)}");
      debugPrint("==========================================");
    }

    debugPrint("🤖 [Foundry] Respuesta: $text");
    return text;
  }

  double _calculateRequestCost(int inputTokens, int outputTokens) {
    final pricing = modelPricing[model];
    if (pricing == null) return 0.0;
    return (inputTokens / 1000000) * pricing['input']! +
        (outputTokens / 1000000) * pricing['output']!;
  }

  @override
  Future<List<String>> generateBatch(
    List<String> prompts, {
    String? systemPrompt,
  }) async {
    debugPrint(
      "📚 [Foundry] generateBatch iniciado con $model (${prompts.length} prompts)",
    );
    final List<String> results = [];

    for (int i = 0; i < prompts.length; i++) {
      debugPrint("➡️ [${i + 1}/${prompts.length}] Procesando...");
      final result = await generate(prompts[i], systemPrompt: systemPrompt);
      results.add(result);
      debugPrint("✅ [${i + 1}/${prompts.length}] Completado");
    }

    debugPrint("📦 [Foundry] BATCH COMPLETADO");
    return results;
  }
}
