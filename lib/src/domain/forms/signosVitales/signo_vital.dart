/// Representa un signo vital tal como llega en el JSON de entrada
/// (`signosVitales.listaSignosVitales[i]`).
class SignoVital {
  const SignoVital({
    required this.descripcion,
    required this.nombre,
    required this.campoId,
    required this.minimo,
    required this.maximo,
    this.unidad,
    this.tipoDato,
  });

  factory SignoVital.fromJson(Map<String, dynamic> json) {
    return SignoVital(
      descripcion: json['descripcion'] as String,
      nombre: json['nombre'] as String,
      campoId: (json['campoId'] as num).toInt(),
      minimo: (json['minimo'] as num).toDouble(),
      maximo: (json['maximo'] as num).toDouble(),
      unidad: json['unidad'] as String?,
      tipoDato: json['tipoDato'] as String?,
    );
  }

  final String descripcion;
  final String nombre;
  final int campoId;
  final double minimo;
  final double maximo;
  final String? unidad;
  final String? tipoDato;
}
