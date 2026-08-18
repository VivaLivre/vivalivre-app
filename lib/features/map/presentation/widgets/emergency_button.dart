import 'package:flutter/material.dart';

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
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Achar Banheiro Agora',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
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
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.primary, size: 26),
          ),
        ),
      ],
    );
  }
}
