import 'package:equatable/equatable.dart';

/// Entidade que representa uma avaliação de banheiro
class BathroomReview extends Equatable {
  final String id;
  final String bathroomId;
  final String userId;
  final int rating;
  final String? title;
  final String? comment;
  final int? cleanlinessRating;
  final int? accessibilityRating;
  final int? spaciosunessRating;
  final int helpfulCount;
  final int unhelpfulCount;
  final String status;
  final List<String> photos;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userName;
  final String? userAvatar;

  const BathroomReview({
    required this.id,
    required this.bathroomId,
    required this.userId,
    required this.rating,
    this.title,
    this.comment,
    this.cleanlinessRating,
    this.accessibilityRating,
    this.spaciosunessRating,
    required this.helpfulCount,
    required this.unhelpfulCount,
    required this.status,
    required this.photos,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatar,
  });

  @override
  List<Object?> get props => [
    id,
    bathroomId,
    userId,
    rating,
    title,
    comment,
    cleanlinessRating,
    accessibilityRating,
    spaciosunessRating,
    helpfulCount,
    unhelpfulCount,
    status,
    photos,
    createdAt,
    updatedAt,
    userName,
    userAvatar,
  ];
}

/// Entidade que representa estatísticas de ratings de um banheiro
class BathroomRatingStats extends Equatable {
  final String bathroomId;
  final int totalReviews;
  final double averageRating;
  final double avgCleanliness;
  final double avgAccessibility;
  final double avgSpaciosuneness;
  final Map<int, int> ratingDistribution;

  const BathroomRatingStats({
    required this.bathroomId,
    required this.totalReviews,
    required this.averageRating,
    required this.avgCleanliness,
    required this.avgAccessibility,
    required this.avgSpaciosuneness,
    required this.ratingDistribution,
  });

  @override
  List<Object?> get props => [
    bathroomId,
    totalReviews,
    averageRating,
    avgCleanliness,
    avgAccessibility,
    avgSpaciosuneness,
    ratingDistribution,
  ];
}

/// Entidade que representa um voto de utilidade
class ReviewHelpfulVote extends Equatable {
  final String id;
  final String reviewId;
  final String userId;
  final bool isHelpful;
  final DateTime createdAt;

  const ReviewHelpfulVote({
    required this.id,
    required this.reviewId,
    required this.userId,
    required this.isHelpful,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, reviewId, userId, isHelpful, createdAt];
}
