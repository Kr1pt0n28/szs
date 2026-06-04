class ItemEducacionFamilia {
  const ItemEducacionFamilia({
    required this.codigo,
    required this.descripcion,
    required this.nombre,
  });

  final int codigo;
  final String descripcion;
  final String nombre;

  factory ItemEducacionFamilia.fromJson(Map<String, dynamic> json) {
    return ItemEducacionFamilia(
      codigo: json['codigo'] as int,
      descripcion: json['descripcion'] as String,
      nombre: json['nombre'] as String,
    );
  }
}

