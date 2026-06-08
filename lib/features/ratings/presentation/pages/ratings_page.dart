import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';
import 'package:viva_livre_app/features/map/domain/entities/bathroom.dart';
import '../bloc/rating_bloc.dart';
import '../widgets/star_rating_widget.dart';
import '../widgets/review_form_widget.dart';
import '../widgets/review_list_widget.dart';
import '../widgets/bathroom_details_widget.dart';
import 'package:viva_livre_app/features/ratings/domain/entities/bathroom_review.dart';
import 'package:viva_livre_app/features/crowdsource/presentation/bloc/crowdsource_bloc.dart';
import 'package:viva_livre_app/features/crowdsource/presentation/bloc/crowdsource_event.dart';
import 'package:viva_livre_app/features/crowdsource/presentation/bloc/crowdsource_state.dart';

/// Page displaying bathroom ratings, statistics, and review functionality.
class RatingsPage extends StatefulWidget {
  final String bathroomId;
  final String? bathroomName;
  final Bathroom? bathroom;

  const RatingsPage({
    super.key,
    required this.bathroomId,
    this.bathroomName,
    this.bathroom,
  });

  @override
  State<RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends State<RatingsPage> {
  late final RatingBloc _ratingBloc;
  BathroomRatingStats? _stats;
  List<BathroomReview>? _reviews;

  @override
  void initState() {
    super.initState();
    _ratingBloc = context.read<RatingBloc>();
    _loadRatings();
  }

  void _loadRatings() {
    _ratingBloc.add(LoadBathroomReviews(bathroomId: widget.bathroomId));
    _ratingBloc.add(LoadBathroomRatingStats(widget.bathroomId));
  }

  void _showReviewModal({BathroomReview? existingReview}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      existingReview != null ? 'Editar Avaliação' : 'Avaliar Banheiro',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  child: BlocListener<RatingBloc, RatingState>(
                    listener: (context, state) {
                      if (state is ReviewCreated || state is ReviewUpdated) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state is ReviewCreated ? 'Avaliação submetida com sucesso!' : 'Avaliação atualizada com sucesso!')),
                        );
                        _loadRatings();
                      } else if (state is RatingError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message)),
                        );
                      }
                    },
                    child: BlocBuilder<RatingBloc, RatingState>(
                      builder: (context, state) {
                        return ReviewFormWidget(
                          isLoading: state is ReviewAdding || state is ReviewUpdating,
                          initialRating: existingReview?.rating.toString(),
                          initialComment: existingReview?.comment,
                          initialCleanlinessRating: existingReview?.cleanlinessRating,
                          initialAccessibilityRating: existingReview?.accessibilityRating,
                          onSubmit: (rating, comment, cleanliness, accessibility) {
                            if (existingReview != null) {
                              _ratingBloc.add(
                                UpdateReview(
                                  reviewId: existingReview.id,
                                  rating: rating,
                                  title: 'Avaliação',
                                  comment: comment,
                                  cleanlinessRating: cleanliness,
                                  accessibilityRating: accessibility,
                                ),
                              );
                            } else {
                              _ratingBloc.add(
                                CreateReview(
                                  bathroomId: widget.bathroomId,
                                  rating: rating,
                                  title: 'Avaliação',
                                  comment: comment,
                                  cleanlinessRating: cleanliness,
                                  accessibilityRating: accessibility,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bathroomName ?? 'Avaliações'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'report') {
                _showReportDialog(context);
              } else if (value == 'suggest') {
                if (widget.bathroom != null) {
                  _showSuggestChangesSheet(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dados insuficientes para propor alteração.')),
                  );
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18, color: Color(0xFFEF4444)),
                    SizedBox(width: 10),
                    Text('Reportar banheiro', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'suggest',
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 18, color: Theme.of(context).colorScheme.primary), // _kBlue equivalent
                    const SizedBox(width: 10),
                    const Text('Propor alteração', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocListener<RatingBloc, RatingState>(
        listener: (context, state) {
          if (state is BathroomRatingStatsLoaded) {
            setState(() => _stats = state.stats);
          } else if (state is BathroomReviewsLoaded) {
            setState(() => _reviews = state.reviews);
          } else if (state is HelpfulVoteRecorded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voto registado com sucesso')),
            );
          } else if (state is ReviewDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Avaliação excluída com sucesso')),
            );
            _loadRatings();
          } else if (state is RatingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: RefreshIndicator(
          onRefresh: () async => _loadRatings(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Banner
              if (widget.bathroom?.photoUrl != null && widget.bathroom!.photoUrl!.isNotEmpty)
                Image.network(
                  widget.bathroom!.photoUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.wc,
                      size: 64,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),

              // Bathroom Details Section
              if (widget.bathroom != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: BathroomDetailsWidget(bathroom: widget.bathroom!),
                ),

              // Rating Stats Section
              if (_stats == null && _reviews == null)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_stats != null)
                _RatingStatsSection(stats: _stats!),

              // Avaliar Button
              Builder(
                builder: (context) {
                  bool hasReviewed = false;
                  BathroomReview? userReview;

                  final authState = context.read<AuthBloc>().state;
                  final currentUserId = authState is AuthAuthenticated ? authState.user.id.toString() : null;

                  if (_reviews != null && currentUserId != null) {
                    try {
                      userReview = _reviews!.firstWhere((r) => r.userId == currentUserId);
                      hasReviewed = true;
                    } catch (_) {}
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showReviewModal(existingReview: userReview),
                        icon: Icon(hasReviewed ? Icons.edit_note_rounded : Icons.rate_review),
                        label: Text(hasReviewed ? 'Editar Avaliação' : 'Avaliar este Banheiro'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Reviews List Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comentários dos Utilizadores',
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (_reviews != null)
                      Builder(
                        builder: (context) {
                          final authState = context.read<AuthBloc>().state;
                          final currentUserId = authState is AuthAuthenticated ? authState.user.id.toString() : null;

                          return ReviewListWidget(
                            reviews: _reviews!,
                            currentUserId: currentUserId,
                            onDeleteReview: (reviewId) {
                              _ratingBloc.add(DeleteReview(reviewId));
                            },
                            onHelpfulVote: (reviewId, isHelpful) {
                              _ratingBloc.add(
                                VoteHelpful(
                                  reviewId: reviewId,
                                  isHelpful: isHelpful,
                                ),
                              );
                            },
                          );
                        },
                      ),

                    BlocBuilder<RatingBloc, RatingState>(
                      builder: (context, state) {
                        if (state is RatingError && _reviews == null) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.message,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadRatings,
                                    child: const Text('Tenta Novamente'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  //  Report Dialog
  // ───────────────────────────────────────────────────────────────────────
  void _showReportDialog(BuildContext context) {
    String? selectedReason;
    final otherReasonController = TextEditingController();
    final bloc = context.read<CrowdsourceBloc>();

    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: BlocListener<CrowdsourceBloc, CrowdsourceState>(
          listener: (ctx, state) {
            if (state is CrowdsourceSuccess) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Obrigado pela sua contribuição! A nossa equipa vai analisar.'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            } else if (state is CrowdsourceError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
          child: StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.flag_outlined, color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 10),
              Text('Reportar Banheiro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Por que deseja reportar este local?',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              RadioGroup<String>(
                groupValue: selectedReason ?? '',
                onChanged: (val) => setDialogState(() => selectedReason = val),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    'Não existe mais',
                    'Local impróprio / inseguro',
                    'Informações incorretas',
                    'Outro motivo',
                  ].map((reason) => ListTile(
                        title: Text(reason, style: const TextStyle(fontSize: 14)),
                        leading: Radio<String>(
                          value: reason,
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onTap: () => setDialogState(() => selectedReason = reason),
                      )).toList(),
                ),
              ),
              if (selectedReason == 'Outro motivo') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: otherReasonController,
                  decoration: InputDecoration(
                    hintText: 'Especifique o motivo...',
                    hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      String reason = selectedReason!;
                      String? desc = (reason == 'Outro motivo') ? otherReasonController.text : null;
                      bloc.add(SubmitReportEvent(
                        bathroomId: widget.bathroomId,
                        reason: reason,
                        description: desc,
                      ));
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: BlocBuilder<CrowdsourceBloc, CrowdsourceState>(
                builder: (context, state) {
                  if (state is CrowdsourceLoading) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    );
                  }
                  return const Text('Enviar Reporte');
                },
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  //  Suggest Changes BottomSheet
  // ───────────────────────────────────────────────────────────────────────
  void _showSuggestChangesSheet(BuildContext context) {
    if (widget.bathroom == null) return;
    
    bool suggestAccessible = widget.bathroom!.isAccessible;
    bool suggestChangingTable = widget.bathroom!.hasChangingTable;
    bool suggestFree = widget.bathroom!.isFree;

    final bloc = context.read<CrowdsourceBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: BlocListener<CrowdsourceBloc, CrowdsourceState>(
          listener: (ctx, state) {
            if (state is CrowdsourceSuccess) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Obrigado pela sua contribuição! A nossa equipa vai analisar.'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            } else if (state is CrowdsourceError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
          child: StatefulBuilder(
            builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                  const SizedBox(width: 10),
                  const Text('Propor Alteração',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Marque as informações que deseja alterar',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                title: const Text('♿ Acessível para PCD', style: TextStyle(fontSize: 14)),
                value: suggestAccessible,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) => setSheetState(() => suggestAccessible = val ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('🍼 Possui Trocador', style: TextStyle(fontSize: 14)),
                value: suggestChangingTable,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) => setSheetState(() => suggestChangingTable = val ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('🆓 Gratuito', style: TextStyle(fontSize: 14)),
                value: suggestFree,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) => setSheetState(() => suggestFree = val ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final updates = {
                      "is_accessible": suggestAccessible,
                      "has_changing_table": suggestChangingTable,
                      "is_free": suggestFree,
                    };
                    bloc.add(SubmitSuggestionEvent(
                      bathroomId: widget.bathroomId,
                      suggestedUpdates: updates,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: BlocBuilder<CrowdsourceBloc, CrowdsourceState>(
                    builder: (context, state) {
                      if (state is CrowdsourceLoading) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        );
                      }
                      return const Text('Enviar Sugestão',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }
}

/// Section displaying rating statistics and distribution.
class _RatingStatsSection extends StatelessWidget {
  final dynamic stats;

  const _RatingStatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Rating
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Avaliação Geral',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stats.averageRating.toStringAsFixed(1),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            StarRatingWidget(
                              initialRating: stats.averageRating,
                              readOnly: true,
                              size: 20,
                            ),
                            Text(
                              '${stats.totalReviews} ${stats.totalReviews == 1 ? 'avaliação' : 'avaliações'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RatingBarItem(
                          label: 'Limpeza',
                          value: stats.avgCleanliness,
                        ),
                        const SizedBox(height: 12),
                        _RatingBarItem(
                          label: 'Acessibilidade',
                          value: stats.avgAccessibility,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Rating Distribution Chart
              if (stats.ratingDistribution != null && stats.ratingDistribution!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distribuição de Avaliações',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(5, (index) {
                        final rating = 5 - index;
                        final count = stats.ratingDistribution![rating] ?? 0;
                        final percentage = stats.totalReviews > 0
                            ? (count / stats.totalReviews * 100).toStringAsFixed(0)
                            : '0';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '$rating',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.star, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: stats.totalReviews > 0 ? count / stats.totalReviews : 0,
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '$percentage%',
                                  style: theme.textTheme.labelSmall,
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual rating bar item.
class _RatingBarItem extends StatelessWidget {
  final String label;
  final double value;

  const _RatingBarItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = value / 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value.toStringAsFixed(1),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
