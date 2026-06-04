import 'package:flutter/services.dart';

/// Configuración central del paquete sura_voxia.
///
/// Debe inicializarse una vez al arrancar la app:
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await VoxiaConfig.initialize();
///   runApp(const MyApp());
/// }
/// ```
class VoxiaConfig {
  VoxiaConfig._();

  static String? _azureFoundryEndpoint;
  static String? _azureFoundryApiKey;
  static String? _systemPrompt;
  static bool _initialized = false;

  /// Carga la configuración desde el archivo `.env` del paquete.
  ///
  /// Si falla la carga (archivo no encontrado, clave ausente), lanza
  /// [StateError] con un mensaje descriptivo.
  static Future<void> initialize() async {
    if (_initialized) return;

    String raw;
    try {
      raw = await rootBundle.loadString('packages/sura_voxia/.env');
    } catch (_) {
      // Fallback: intentar desde la ruta directa (útil en el propio paquete/demo)
      try {
        raw = await rootBundle.loadString('.env');
      } catch (e) {
        throw StateError(
          'VoxiaConfig: no se encontró el archivo .env. '
          'Asegúrate de que el asset esté declarado en pubspec.yaml. '
          'Error: $e',
        );
      }
    }

    final Map<String, String> vars = _parseEnv(raw);

    // Azure AI Foundry — opcionales, solo se requieren al usar FoundryService
    final String? azureEndpoint = vars['AZURE_FOUNDRY_ENDPOINT'];
    final String? azureKey = vars['AZURE_FOUNDRY_API_KEY'];
    if (azureEndpoint != null && azureEndpoint.trim().isNotEmpty) {
      _azureFoundryEndpoint = azureEndpoint.trim();
    }
    if (azureKey != null && azureKey.trim().isNotEmpty) {
      _azureFoundryApiKey = azureKey.trim();
    }

    // System prompt — opcional, se desescapa \n → nueva línea real
    final String? rawSystemPrompt = vars['VOXIA_SYSTEM_PROMPT'];
    if (rawSystemPrompt != null && rawSystemPrompt.trim().isNotEmpty) {
      _systemPrompt = rawSystemPrompt.trim().replaceAll(r'\n', '\n');
    }

    _initialized = true;
  }

  /// Endpoint base de Azure AI Foundry (sin slash final).
  ///
  /// Lanza [StateError] si no está definido en el archivo .env.
  static String get azureFoundryEndpoint {
    if (_azureFoundryEndpoint == null) {
      throw StateError(
        'VoxiaConfig: AZURE_FOUNDRY_ENDPOINT no está definido en el archivo .env.',
      );
    }
    return _azureFoundryEndpoint!;
  }

  /// Clave de API de Azure AI Foundry.
  ///
  /// Lanza [StateError] si no está definida en el archivo .env.
  static String get azureFoundryApiKey {
    if (_azureFoundryApiKey == null) {
      throw StateError(
        'VoxiaConfig: AZURE_FOUNDRY_API_KEY no está definido en el archivo .env.',
      );
    }
    return _azureFoundryApiKey!;
  }

  /// System prompt cargado desde el archivo .env.
  ///
  /// Lanza [StateError] si no está definido en el archivo .env.
  static String get systemPrompt {
    if (_systemPrompt == null) {
      throw StateError(
        'VoxiaConfig: VOXIA_SYSTEM_PROMPT no está definido en el archivo .env.',
      );
    }
    return _systemPrompt!;
  }

  static Map<String, String> _parseEnv(String content) {
    final Map<String, String> result = {};
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx == -1) continue;
      final key = trimmed.substring(0, idx).trim();
      final value = trimmed.substring(idx + 1).trim();
      if (key.isNotEmpty) result[key] = value;
    }
    return result;
  }
}
