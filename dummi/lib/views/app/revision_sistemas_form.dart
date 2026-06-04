import 'package:flutter/material.dart';
import 'sura_colors.dart';

/// Vista del formulario de Revisión por Sistemas.
/// Recibe las secciones del JSON y el mapa de respuestas desde el parent.
/// Notifica cambios mediante [onAnswerChanged].
class RevisionSistemasForm extends StatelessWidget {
  const RevisionSistemasForm({
    super.key,
    required this.secciones,
    required this.answers,
    required this.onAnswerChanged,
  });

  final List<Map<String, dynamic>> secciones;

  /// Map<codigo.toString(), valor> — puede estar vacío al inicio.
  final Map<String, String> answers;

  /// Callback: (codigo, nuevoValor) — nuevoValor es null cuando se deselecciona.
  final void Function(String codigo, String? nuevoValor) onAnswerChanged;

  static const List<String> _opciones = [
    'refiere',
    'no refiere',
    'no aplica',
  ];

  static const Map<String, Color> _colores = {
    'refiere': kVerdeExito,
    'no refiere': kRojoError,
    'no aplica': Color(0xFF888888),
  };

  @override
  Widget build(BuildContext context) {
    if (secciones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final seccion in secciones) _buildSeccionCard(seccion),
      ],
    );
  }

  Widget _buildSeccionCard(Map<String, dynamic> seccion) {
    final descripcion = seccion['descripcion'] as String;
    final items = (seccion['items'] as List).cast<Map<String, dynamic>>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de sección
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kAzulSura.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_outlined,
                    size: 16, color: kAzulSura),
                const SizedBox(width: 8),
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kAzulSura,
                  ),
                ),
              ],
            ),
          ),
          // Ítems
          for (int i = 0; i < items.length; i++) ...[
            _buildItemRow(items[i]),
            if (i < items.length - 1)
              Divider(
                height: 1,
                color: Colors.grey.withValues(alpha: 0.1),
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final codigo = (item['codigo'] as num).toInt().toString();
    final descripcion = item['descripcion'] as String;
    final valorActual = answers[codigo];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            descripcion,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final opcion in _opciones) ...[
                _RadioChip(
                  label: opcion,
                  selected: valorActual == opcion,
                  color: _colores[opcion]!,
                  onTap: () {
                    // Si ya está seleccionada → deseleccionar, si no → seleccionar
                    onAnswerChanged(
                      codigo,
                      valorActual == opcion ? null : opcion,
                    );
                  },
                ),
                if (opcion != 'no aplica') const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RadioChip extends StatelessWidget {
  const _RadioChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: selected ? color : Colors.grey.withValues(alpha: 0.35),
            width: selected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? color : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
