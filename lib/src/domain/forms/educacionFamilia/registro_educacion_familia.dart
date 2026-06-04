/// Un registro de educación a la familia tal como debe aparecer en
/// `registroEducacionFamilia[i]` del JSON de salida.
/// valorId: 11 = "si", 12 = "no", null para el guion.
class RegistroEducacionFamilia {
  const RegistroEducacionFamilia({
    required this.nombreId,
    required this.nombre,
    required this.valorId,
    required this.valor,
  });

  final int? nombreId;
  final String nombre;
  final int? valorId;
  final String valor;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'nombreId': nombreId,
        'nombre': nombre,
        'valorId': valorId,
        'valor': valor,
      };
}

