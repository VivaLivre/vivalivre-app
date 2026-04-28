import 'package:flutter/material.dart';

const _kBlue = Color(0xFF2563EB);
const _kSurface = Color(0xFFF1F5F9);

class EmergencyButton extends StatelessWidget {
  final VoidCallback onAddBathroom;
  final VoidCallback onEmergency;

  const EmergencyButton({
    super.key,
    required this.onAddBathroom,
    required this.onEmergency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Pílula "Achar Banheiro Agora"
        Expanded(
          child: GestureDetector(
            onTap: onEmergency,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: _kBlue,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Achar Banheiro Agora',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // FAB "Adicionar banheiro"
        GestureDetector(
          onTap: onAddBathroom,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _kSurface),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: _kBlue, size: 26),
          ),
        ),
      ],
    );
  }
}
