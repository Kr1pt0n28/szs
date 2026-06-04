import 'package:flutter/material.dart';
import 'sura_colors.dart';

/// Vista del formulario de Signos Vitales.
/// Recibe los datos y controladores desde el parent (AppView).
class SignosVitalesForm extends StatelessWidget {
  const SignosVitalesForm({
    super.key,
    required this.vitals,
    required this.fieldControllers,
    this.onFieldChanged,
  });

  final List<Map<String, dynamic>> vitals;
  final Map<String, TextEditingController> fieldControllers;
  /// Llamado cada vez que el usuario edita cualquier campo.
  final VoidCallback? onFieldChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                Icon(Icons.monitor_heart_outlined, size: 16, color: kAzulSura),
                SizedBox(width: 8),
                Text(
                  'Signos Vitales',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kAzulSura,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < vitals.length; i++)
            _buildVitalField(vitals[i], isLast: i == vitals.length - 1),
        ],
      ),
    );
  }

  Widget _buildVitalField(Map<String, dynamic> vital, {required bool isLast}) {
    final campoId = vital['campoId'].toString();
    final descripcion = vital['descripcion'] as String;
    final unidad = vital['unidad'] as String?;
    final minimo = vital['minimo'] as num;
    final maximo = vital['maximo'] as num;
    final tc = fieldControllers[campoId];

    final rangoHint =
        unidad != null ? '$minimo – $maximo $unidad' : '$minimo – $maximo';

    return Column(
      children: [
        Padding(
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
              Text(
                rangoHint,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: tc,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Valor numérico',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: kAquaSura, width: 1.5),
                  ),
                ),
                onChanged: (_) => onFieldChanged?.call(),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.1),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
