/// Representa un ítem individual dentro de una sección de revisión por sistemas,
/// tal como llega en `revisionSistemas[i].items[j]` del JSON de entrada.
class ItemRevisionSistema {
  const ItemRevisionSistema({
    required this.nombre,
    required this.descripcion,
    required this.codigo,
  });

  factory ItemRevisionSistema.fromJson(Map<String, dynamic> json) {
    return ItemRevisionSistema(
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      codigo: (json['codigo'] as num).toInt(),
    );
  }

  final String nombre;
  final String descripcion;
  final int codigo;
}
