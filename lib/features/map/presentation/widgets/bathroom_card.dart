import 'package:flutter/material.dart';
import 'package:viva_livre_app/features/map/domain/entities/bathroom.dart';

const _kBlue = Color(0xFF2563EB);
const _kBlueSoft = Color(0xFFEFF6FF);
const _kBlueBorder = Color(0xFFBFDBFE);
const _kText = Color(0xFF111827);
const _kSubText = Color(0xFF6B7280);
const _kGray = Color(0xFF9CA3AF);

class BathroomCard extends StatelessWidget {
  final Bathroom bathroom;
  final String distanceText;
  final VoidCallback onClose;
  final VoidCallback? onDetails;

  const BathroomCard({
    super.key,
    required this.bathroom,
    required this.distanceText,
    required this.onClose,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = bathroom.isOpen;
    final tags = bathroom.tags;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Preview
          if (bathroom.photoUrl != null && bathroom.photoUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  bathroom.photoUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 32,
                          color: _kSubText,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOpen
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOpen
                                  ? const Color(0xFF10B981)
                                  : _kGray,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpen ? 'Aberto agora' : 'Fechado',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isOpen
                                  ? const Color(0xFF059669)
                                  : _kGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bathroom.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$distanceText de distância',
                      style: const TextStyle(fontSize: 13, color: _kSubText),
                    ),
                  ],
                ),
              ),
              // Close button
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: _kSubText,
                  ),
                ),
              ),
            ],
          ),

          // Observations (admin notes)
          if (bathroom.observations != null &&
              bathroom.observations!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: Color(0xFFB45309)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bathroom.observations!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          // Tags
          Wrap(
            spacing: 6,
            children: [
              _TagChip(
                icon: Icons.star_rounded,
                label: '${bathroom.rating}',
                bg: const Color(0xFFFFFBEB),
                border: const Color(0xFFFDE68A),
                fg: const Color(0xFFB45309),
              ),
              ...tags.map(
                (tag) => _TagChip(
                  label: tag,
                  bg: _kBlueSoft,
                  border: _kBlueBorder,
                  fg: _kBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isOpen ? () {} : null,
                  icon: Icon(
                    isOpen
                        ? Icons.navigation_rounded
                        : Icons.block_rounded,
                    size: 18,
                  ),
                  label: Text(isOpen ? 'Ir agora' : 'Fechado'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: isOpen ? _kBlue : _kGray,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: _kGray,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFF374151),
                  ),
                  label: const Text(
                    'Detalhes',
                    style: TextStyle(color: Color(0xFF374151)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _TagChip extends StatelessWidget {
  final String label;
  final Color bg, border, fg;
  final IconData? icon;

  const _TagChip({
    required this.label,
    required this.bg,
    required this.border,
    required this.fg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
