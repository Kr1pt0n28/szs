import 'package:flutter/material.dart';
import 'sura_colors.dart';

/// Vista del formulario de Educación a la Familia.
/// Muestra cada ítem como un toggle (si/no), por defecto "no".
class EducacionFamiliaForm extends StatelessWidget {
  const EducacionFamiliaForm({
    super.key,
    required this.items,
    required this.toggles,
    required this.onToggle,
  });

  /// Items del JSON: List<Map> con keys 'codigo', 'descripcion', 'nombre'.
  final List<Map<String, dynamic>> items;

  /// Map<codigo.toString(), bool> — true = "si", absent/false = "no".
  final Map<String, bool> toggles;

  /// Callback: (codigo, nuevoValor).
  final void Function(String codigo, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kAzulSura.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.family_restroom_outlined, size: 16, color: kAzulSura),
                SizedBox(width: 8),
                Text(
                  'Temas impartidos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kAzulSura,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < items.length; i++)
            _buildItem(items[i], i == items.length - 1),
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item, bool isLast) {
    final codigo = item['codigo'].toString();
    final descripcion = item['descripcion'] as String;
    final isOn = toggles[codigo] ?? false;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: isOn ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: isOn,
                onChanged: (v) => onToggle(codigo, v),
                activeColor: kVerdeExito,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.grey.withValues(alpha: 0.12),
          ),
      ],
    );
  }
}

