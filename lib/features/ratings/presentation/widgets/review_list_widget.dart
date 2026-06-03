import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../ratings/domain/entities/bathroom_review.dart';
import 'star_rating_widget.dart';

/// Widget displaying a list of reviews with helpful voting functionality.
///
/// Features:
/// - Displays reviews with ratings, comments, and timestamps
/// - Helpful/Unhelpful vote buttons
/// - Empty state message
/// - Responsive layout
class ReviewListWidget extends StatefulWidget {
  final List<BathroomReview> reviews;
  final Function(String reviewId, bool isHelpful)? onHelpfulVote;
  final String? currentUserId;
  final Function(String reviewId)? onDeleteReview;
  final bool isLoading;

  const ReviewListWidget({
    super.key,
    required this.reviews,
    this.onHelpfulVote,
    this.currentUserId,
    this.onDeleteReview,
    this.isLoading = false,
  });

  @override
  State<ReviewListWidget> createState() => _ReviewListWidgetState();
}

class _ReviewListWidgetState extends State<ReviewListWidget> {
  final Map<String, bool?> _votedReviews = {};

  void _handleHelpfulVote(String reviewId, bool isHelpful) {
    setState(() => _votedReviews[reviewId] = isHelpful);
    widget.onHelpfulVote?.call(reviewId, isHelpful);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Sem avaliações ainda',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sê o primeiro a avaliar este banheiro',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.reviews.length,
      separatorBuilder: (context, index) => Divider(
        height: 24,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      itemBuilder: (context, index) {
        final review = widget.reviews[index];
        return _ReviewCard(
          review: review,
          currentUserId: widget.currentUserId,
          onDeleteReview: widget.onDeleteReview,
          onHelpfulVote: _handleHelpfulVote,
          userVote: _votedReviews[review.id],
        );
      },
    );
  }
}

/// Individual review card with rating, comment, and helpful voting.
class _ReviewCard extends StatelessWidget {
  final BathroomReview review;
  final String? currentUserId;
  final Function(String reviewId)? onDeleteReview;
  final Function(String, bool) onHelpfulVote;
  final bool? userVote;

  const _ReviewCard({
    required this.review,
    required this.onHelpfulVote,
    this.currentUserId,
    this.onDeleteReview,
    this.userVote,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje às ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks semana${weeks > 1 ? 's' : ''} atrás';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months mês${months > 1 ? 'es' : ''} atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Rating and Date
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StarRatingWidget(
                    initialRating: review.rating.toDouble(),
                    readOnly: true,
                    size: 20,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(review.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            if (currentUserId != null && currentUserId == review.userId)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.outline),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'delete') {
                    onDeleteReview?.call(review.id);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 20),
                        const SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: theme.colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Comment
        if (review.comment != null && review.comment!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              review.comment!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Helpful Voting
        Row(
          children: [
            Text(
              'Útil?',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: 8),
            // Helpful Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onHelpfulVote(review.id, true),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_up_outlined,
                        size: 16,
                        color: userVote == true ? theme.colorScheme.primary : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sim (${review.helpfulCount})',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: userVote == true ? theme.colorScheme.primary : theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Unhelpful Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onHelpfulVote(review.id, false),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_down_outlined,
                        size: 16,
                        color: userVote == false ? theme.colorScheme.primary : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Não (${review.unhelpfulCount})',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: userVote == false ? theme.colorScheme.primary : theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
