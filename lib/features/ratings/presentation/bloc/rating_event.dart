part of 'rating_bloc.dart';

/// Eventos do RatingBloc
abstract class RatingEvent extends Equatable {
  const RatingEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega reviews de um banheiro
class LoadBathroomReviews extends RatingEvent {
  final String bathroomId;
  final String sort;
  final int limit;
  final int offset;

  const LoadBathroomReviews({
    required this.bathroomId,
    this.sort = 'recent',
    this.limit = 10,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [bathroomId, sort, limit, offset];
}

/// Carrega estatísticas de ratings de um banheiro
class LoadBathroomRatingStats extends RatingEvent {
  final String bathroomId;

  const LoadBathroomRatingStats(this.bathroomId);

  @override
  List<Object?> get props => [bathroomId];
}

/// Cria uma nova avaliação
class CreateReview extends RatingEvent {
  final String bathroomId;
  final int rating;
  final String? title;
  final String? comment;
  final int? cleanlinessRating;
  final int? accessibilityRating;
  final int? spaciosunessRating;

  const CreateReview({
    required this.bathroomId,
    required this.rating,
    this.title,
    this.comment,
    this.cleanlinessRating,
    this.accessibilityRating,
    this.spaciosunessRating,
  });

  @override
  List<Object?> get props => [
    bathroomId,
    rating,
    title,
    comment,
    cleanlinessRating,
    accessibilityRating,
    spaciosunessRating,
  ];
}

/// Atualiza uma avaliação
class UpdateReview extends RatingEvent {
  final String reviewId;
  final int? rating;
  final String? title;
  final String? comment;
  final int? cleanlinessRating;
  final int? accessibilityRating;
  final int? spaciosunessRating;

  const UpdateReview({
    required this.reviewId,
    this.rating,
    this.title,
    this.comment,
    this.cleanlinessRating,
    this.accessibilityRating,
    this.spaciosunessRating,
  });

  @override
  List<Object?> get props => [
    reviewId,
    rating,
    title,
    comment,
    cleanlinessRating,
    accessibilityRating,
    spaciosunessRating,
  ];
}

/// Deleta uma avaliação
class DeleteReview extends RatingEvent {
  final String reviewId;

  const DeleteReview(this.reviewId);

  @override
  List<Object?> get props => [reviewId];
}

/// Vota se uma avaliação foi útil
class VoteHelpful extends RatingEvent {
  final String reviewId;
  final bool isHelpful;

  const VoteHelpful({
    required this.reviewId,
    required this.isHelpful,
  });

  @override
  List<Object?> get props => [reviewId, isHelpful];
}
