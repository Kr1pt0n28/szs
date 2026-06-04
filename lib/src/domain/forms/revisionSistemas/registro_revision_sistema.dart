/// Un ítem de revisión por sistemas con su valor registrado, tal como debe
/// aparecer en `registroRevisionSistemas[i]` del JSON de salida.
class RegistroRevisionSistema {
  const RegistroRevisionSistema({
    required this.conceptoId,
    required this.nombre,
    required this.valor,
  });

  /// null solo para el registro especial "guion".
  final int? conceptoId;
  final String nombre;

  /// Uno de: "refiere", "no refiere", "no aplica", o texto libre para el guion.
  final String valor;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'conceptoId': conceptoId,
        'nombre': nombre,
        'valor': valor,
      };
}
