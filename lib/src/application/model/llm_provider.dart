abstract class LlmProvider {
  Future<String> generate(String userPrompt, {String? systemPrompt});

  Future<List<String>> generateBatch(List<String> prompts, {String? systemPrompt});
}
