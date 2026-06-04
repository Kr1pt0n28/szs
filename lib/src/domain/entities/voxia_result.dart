import 'voxia_form_output.dart';

/// Jerarquía sellada de resultados del paquete sura_voxia.
///
/// Todas las operaciones async públicas retornan [VoxiaResult<T>].
/// Usar pattern matching (switch / is) para discriminar subtipos.
sealed class VoxiaResult<T> {
  const VoxiaResult();

  bool get isSuccess => this is! VoxiaFailure<T>;

  /// Mensaje de error si la operación falló, null en caso de éxito.
  String? get error => null;

  /// Shorthand para operaciones sin datos de retorno (login, startListening…).
  /// Retorna [VoxiaSuccess<T>].
  static VoxiaResult<T> success<T>(T data) => VoxiaSuccess<T>(data);

  /// Shorthand para fallos. Retorna [VoxiaFailure<T>].
  static VoxiaResult<T> failure<T>(String error) => VoxiaFailure<T>(error);
}

/// Resultado exitoso de una operación sin payload de formulario.
/// Usado por login, startListening, etc. [data] puede ser null (void ops).
final class VoxiaSuccess<T> extends VoxiaResult<T> {
  const VoxiaSuccess(this.data);
  final T data;

  @override
  String toString() => 'VoxiaSuccess($data)';
}

/// Resultado exitoso de un análisis de formulario con IA.
///
/// - [rawData]: mapa `campoId → valorString` tal como lo devuelve el LLM.
///   Úsalo para rellenar los widgets del formulario.
/// - [completedJson]: snapshot del formulario serializado, listo para enviar.
///   Generado internamente — no requiere que el consumidor pase el schema.
final class VoxiaFormSuccess extends VoxiaResult<Map<String, String>> {
  const VoxiaFormSuccess({required this.rawData, required this.completedJson});

  final Map<String, String> rawData;
  final VoxiaFormOutput completedJson;

  @override
  String toString() =>
      'VoxiaFormSuccess(rawData: ${rawData.length} campos)';
}

/// Resultado fallido con mensaje descriptivo.
final class VoxiaFailure<T> extends VoxiaResult<T> {
  const VoxiaFailure(this._error);
  final String _error;

  @override
  String get error => _error;

  @override
  String toString() => 'VoxiaFailure($_error)';
}
