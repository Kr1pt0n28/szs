/// Un signo vital con su valor registrado, tal como debe
/// aparecer en `registroSignosVitales[i]` del JSON de salida.
class RegistroSignoVital {
  const RegistroSignoVital({
    required this.nombre,
    required this.valor,
    required this.campoId,
    this.tipoDato,
    this.unidad,
  });

  final String nombre;

  /// Valor numérico medido. Usa -1.0 cuando no se registró.
  final double valor;

  final int campoId;
  final String? tipoDato;
  final String? unidad;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'nombre': nombre,
        'valor': valor,
        'campoId': campoId,
        'tipoDato': tipoDato,
        'unidad': unidad,
      };
}
