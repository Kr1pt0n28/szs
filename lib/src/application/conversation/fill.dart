import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../forms/flat_slot.dart';
import '../model/llm_provider.dart';

class Fill {
  Fill({required this.llm, required this.systemPrompt});

  final LlmProvider llm;
  final String systemPrompt;

  /// Envía un único prompt al LLM con todos los [slots] y retorna las respuestas
  /// como Map de slot id → respuesta (texto crudo).
  Future<Map<String, String>> fillFromTranscription({
    required List<FlatSlot> slots,
    required String transcription,
    required String promptRules,
  }) async {
    final prompt = _buildPrompt(
      slots: slots,
      transcription: transcription,
      promptRules: promptRules,
    );
    debugPrint('🚀 - Prompt: $prompt');
    final rawResponse = await llm.generate(
      prompt,
      systemPrompt: systemPrompt,
    );
    debugPrint('🚀- respuesta recibida:\n$rawResponse');
    return _parseResponse(rawResponse);
  }

  String _buildPrompt({
    required List<FlatSlot> slots,
    required String transcription,
    required String promptRules,
  }) {
    final fieldsList = slots
        .map(
          (s) =>
              '{"id": "${s.id}", "label": "${s.label}", "format": "${s.formatHint}", "answer": null}',
        )
        .join(',\n');

    return '''REGLAS ESPECÍFICAS DEL FORMULARIO:
$promptRules

TRANSCRIPCIÓN: > $transcription

JSON:
[$fieldsList]
''';
  }

  Map<String, String> _parseResponse(String rawResponse) {
    final regExp = RegExp(r'\[.*\]', dotAll: true);
    final match = regExp.firstMatch(rawResponse);
    if (match == null) {
      throw FormatException(
        'La IA no devolvió un arreglo JSON válido. Respuesta: ${rawResponse.substring(0, rawResponse.length.clamp(0, 200))}',
      );
    }

    var jsonString = match
        .group(0)!
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    // Elimina comas finales inválidas (ej. antes de ] o })
    jsonString = jsonString.replaceAll(
      RegExp(r',\s*(?=[}\]])', dotAll: true),
      '',
    );
    // Elimina una } suelta justo antes del ] final (artefacto del LLM)
    jsonString = jsonString.replaceAll(
      RegExp(r'(?<=\})\s*\}\s*\]', dotAll: true),
      ']',
    );

    final List<dynamic> decoded = jsonDecode(jsonString);
    final result = <String, String>{};
    for (final item in decoded) {
      final id = item['id']?.toString();
      final answer = item['answer'];
      if (id != null && answer != null) {
        result[id] = answer.toString();
      }
    }
    debugPrint('🚀- respuesta Parseada:\n$result');
    return result;
  }
}

