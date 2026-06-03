part of 'rating_bloc.dart';

/// Estados do RatingBloc
abstract class RatingState extends Equatable {
  const RatingState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class RatingInitial extends RatingState {
  const RatingInitial();
}

/// Carregando reviews
class RatingLoading extends RatingState {
  const RatingLoading();
}

/// Reviews carregados com sucesso
class BathroomReviewsLoaded extends RatingState {
  final List<BathroomReview> reviews;
  final int total;
  final double averageRating;

  const BathroomReviewsLoaded({
    required this.reviews,
    required this.total,
    required this.averageRating,
  });

  @override
  List<Object?> get props => [reviews, total, averageRating];
}

/// Estatísticas de ratings carregadas
class BathroomRatingStatsLoaded extends RatingState {
  final BathroomRatingStats stats;

  const BathroomRatingStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

/// Review criado com sucesso
class ReviewCreated extends RatingState {
  final BathroomReview review;

  const ReviewCreated(this.review);

  @override
  List<Object?> get props => [review];
}

/// Review atualizado com sucesso
class ReviewUpdated extends RatingState {
  final BathroomReview review;

  const ReviewUpdated(this.review);

  @override
  List<Object?> get props => [review];
}

/// Review deletado com sucesso
class ReviewDeleted extends RatingState {
  final String reviewId;

  const ReviewDeleted(this.reviewId);

  @override
  List<Object?> get props => [reviewId];
}

/// Voto registrado com sucesso
class HelpfulVoteRecorded extends RatingState {
  final int helpfulCount;
  final int unhelpfulCount;

  const HelpfulVoteRecorded({
    required this.helpfulCount,
    required this.unhelpfulCount,
  });

  @override
  List<Object?> get props => [helpfulCount, unhelpfulCount];
}


/// Erro ao carregar/processar ratings
class RatingError extends RatingState {
  final String message;

  const RatingError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Adicionando review
class ReviewAdding extends RatingState {
  const ReviewAdding();
}

/// Atualizando review
class ReviewUpdating extends RatingState {
  const ReviewUpdating();
}

/// Deletando review
class ReviewDeleting extends RatingState {
  const ReviewDeleting();
}

/// Enviando voto
class VotingHelpful extends RatingState {
  const VotingHelpful();
}
