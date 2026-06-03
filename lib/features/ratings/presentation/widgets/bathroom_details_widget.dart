import 'package:flutter/material.dart';
import 'package:viva_livre_app/features/map/domain/entities/bathroom.dart';

/// Widget displaying bathroom amenities and details.
///
/// Shows:
/// - Photo (if available)
/// - Address
/// - Amenities (accessibility, changing table, free)
/// - Cleanliness and accessibility ratings
class BathroomDetailsWidget extends StatelessWidget {
  final Bathroom bathroom;

  const BathroomDetailsWidget({
    super.key,
    required this.bathroom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address Section
        if (bathroom.address != null && bathroom.address!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Localização',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bathroom.address!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Amenities Section
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comodidades',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _AmenityChip(
                    icon: Icons.accessible_outlined,
                    label: 'Acessível',
                    isAvailable: bathroom.isAccessible,
                    theme: theme,
                  ),
                  _AmenityChip(
                    icon: Icons.child_care_outlined,
                    label: 'Trocador',
                    isAvailable: bathroom.hasChangingTable,
                    theme: theme,
                  ),
                  _AmenityChip(
                    icon: Icons.local_offer_outlined,
                    label: 'Gratuito',
                    isAvailable: bathroom.isFree,
                    theme: theme,
                  ),
                ],
              ),
            ],
          ),
        ),

      ],
    );
  }
}

/// Individual amenity chip showing availability.
class _AmenityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isAvailable;
  final ThemeData theme;

  const _AmenityChip({
    required this.icon,
    required this.label,
    required this.isAvailable,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAvailable
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isAvailable
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isAvailable
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!isAvailable) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.close,
              size: 14,
              color: theme.colorScheme.outline,
            ),
          ],
        ],
      ),
    );
  }
}

