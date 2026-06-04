import 'item_revision_sistema.dart';

/// Representa una sección de revisión por sistemas (ej. "Revisión General"),
/// tal como aparece en cada elemento de la lista `revisionSistemas` del JSON de entrada.
class SeccionRevisionSistema {
  const SeccionRevisionSistema({
    required this.nombre,
    required this.descripcion,
    required this.items,
  });

  factory SeccionRevisionSistema.fromJson(Map<String, dynamic> json) {
    return SeccionRevisionSistema(
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      items: (json['items'] as List)
          .map((e) => ItemRevisionSistema.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String nombre;
  final String descripcion;
  final List<ItemRevisionSistema> items;
}
