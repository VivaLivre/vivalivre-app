import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viva_livre_app/features/map/domain/entities/bathroom.dart';
import 'package:viva_livre_app/features/ratings/presentation/bloc/rating_bloc.dart';

// Cores dinâmicas definidas no build

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
    final theme = Theme.of(context);
    final _kBlue = theme.colorScheme.primary;
    final _kBlueSoft = theme.colorScheme.primary.withValues(alpha: 0.1);
    final _kBlueBorder = theme.colorScheme.primary.withValues(alpha: 0.3);
    final _kText = theme.colorScheme.onSurface;
    final _kSubText = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final _kGray = theme.dividerColor;

    final isOpen = bathroom.isOpen;
    final tags = bathroom.tags;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? const Color(0xFF1F2937) 
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
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
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
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
                                  ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF10B981))
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
                                  ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                  : _kGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            bathroom.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        BlocBuilder<RatingBloc, RatingState>(
                          builder: (context, state) {
                            if (state is BathroomReviewsLoaded) {
                              if (state.total == 0) return const SizedBox.shrink();
                              return Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${state.averageRating.toStringAsFixed(1)} (${state.total})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _kSubText,
                                    ),
                                  ),
                                ],
                              );
                            }
                            if (state is RatingLoading) {
                              return const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${distanceText} de distância',
                      style: TextStyle(fontSize: 13, color: _kSubText),
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
                  child: Icon(
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
            runSpacing: 6,
            children: [
              if (bathroom.isAccessible)
                _TagChip(
                  icon: Icons.accessible_outlined,
                  label: 'Acessível',
                  bg: _kBlueSoft,
                  border: _kBlueBorder,
                  fg: _kBlue,
                ),
              if (bathroom.hasChangingTable)
                _TagChip(
                  icon: Icons.child_care_outlined,
                  label: 'Trocador',
                  bg: _kBlueSoft,
                  border: _kBlueBorder,
                  fg: _kBlue,
                ),
              if (bathroom.isFree)
                _TagChip(
                  icon: Icons.local_offer_outlined,
                  label: 'Gratuito',
                  bg: _kBlueSoft,
                  border: _kBlueBorder,
                  fg: _kBlue,
                ),
              ...tags
                  .where((tag) => 
                      tag.toLowerCase() != 'acessível' && 
                      tag.toLowerCase() != 'acessivel' && 
                      tag.toLowerCase() != 'trocador' && 
                      tag.toLowerCase() != 'gratuito')
                  .map(
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
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onDetails,
              icon: Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              label: Text(
                'Detalhes e Avaliações',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
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
