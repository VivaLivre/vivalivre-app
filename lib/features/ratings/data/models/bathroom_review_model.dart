import 'package:viva_livre_app/features/ratings/domain/entities/bathroom_review.dart';

/// Modelo de avaliação de banheiro (JSON)
class BathroomReviewModel extends BathroomReview {
  const BathroomReviewModel({
    required super.id,
    required super.bathroomId,
    required super.userId,
    required super.rating,
    super.title,
    super.comment,
    super.cleanlinessRating,
    super.accessibilityRating,
    super.spaciosunessRating,
    required super.helpfulCount,
    required super.unhelpfulCount,
    required super.status,
    required super.photos,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Converte JSON para modelo
  factory BathroomReviewModel.fromJson(Map<String, dynamic> json) {
    return BathroomReviewModel(
      id: json['id'].toString(),
      bathroomId: json['bathroom_id'].toString(),
      userId: json['user_id'].toString(),
      rating: json['rating'] as int,
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      cleanlinessRating: json['cleanliness_rating'] as int?,
      accessibilityRating: json['accessibility_rating'] as int?,
      spaciosunessRating: json['spaciousness_rating'] as int?,
      helpfulCount: json['helpful_count'] as int? ?? 0,
      unhelpfulCount: json['unhelpful_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      photos: List<String>.from(json['photos'] as List? ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converte modelo para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bathroom_id': bathroomId,
      'user_id': userId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'cleanliness_rating': cleanlinessRating,
      'accessibility_rating': accessibilityRating,
      'spaciousness_rating': spaciosunessRating,
      'helpful_count': helpfulCount,
      'unhelpful_count': unhelpfulCount,
      'status': status,
      'photos': photos,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Modelo de estatísticas de ratings
class BathroomRatingStatsModel extends BathroomRatingStats {
  const BathroomRatingStatsModel({
    required super.bathroomId,
    required super.totalReviews,
    required super.averageRating,
    required super.avgCleanliness,
    required super.avgAccessibility,
    required super.avgSpaciosuneness,
    required super.ratingDistribution,
  });

  /// Converte JSON para modelo
  factory BathroomRatingStatsModel.fromJson(Map<String, dynamic> json) {
    final distribution = <int, int>{};
    final ratingDist = json['rating_distribution'] as Map<String, dynamic>?;
    if (ratingDist != null) {
      ratingDist.forEach((key, value) {
        distribution[int.parse(key)] = value as int;
      });
    }

    return BathroomRatingStatsModel(
      bathroomId: json['bathroom_id'].toString(),
      totalReviews: json['total_reviews'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      avgCleanliness: (json['avg_cleanliness'] as num?)?.toDouble() ?? 0.0,
      avgAccessibility: (json['avg_accessibility'] as num?)?.toDouble() ?? 0.0,
      avgSpaciosuneness: (json['avg_spaciousness'] as num?)?.toDouble() ?? 0.0,
      ratingDistribution: distribution,
    );
  }

  /// Converte modelo para JSON
  Map<String, dynamic> toJson() {
    return {
      'bathroom_id': bathroomId,
      'total_reviews': totalReviews,
      'average_rating': averageRating,
      'avg_cleanliness': avgCleanliness,
      'avg_accessibility': avgAccessibility,
      'avg_spaciousness': avgSpaciosuneness,
      'rating_distribution': ratingDistribution,
    };
  }
}

/// Modelo de requisição para criar review
class CreateReviewRequest {
  final int rating;
  final String? title;
  final String? comment;
  final int? cleanlinessRating;
  final int? accessibilityRating;
  final int? spaciosunessRating;

  CreateReviewRequest({
    required this.rating,
    this.title,
    this.comment,
    this.cleanlinessRating,
    this.accessibilityRating,
    this.spaciosunessRating,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'title': title,
      'comment': comment,
      'cleanliness_rating': cleanlinessRating,
      'accessibility_rating': accessibilityRating,
      'spaciousness_rating': spaciosunessRating,
    };
  }
}

/// Modelo de requisição para atualizar review
class UpdateReviewRequest {
  final int? rating;
  final String? title;
  final String? comment;
  final int? cleanlinessRating;
  final int? accessibilityRating;
  final int? spaciosunessRating;

  UpdateReviewRequest({
    this.rating,
    this.title,
    this.comment,
    this.cleanlinessRating,
    this.accessibilityRating,
    this.spaciosunessRating,
  });

  Map<String, dynamic> toJson() {
    return {
      if (rating != null) 'rating': rating,
      if (title != null) 'title': title,
      if (comment != null) 'comment': comment,
      if (cleanlinessRating != null) 'cleanliness_rating': cleanlinessRating,
      if (accessibilityRating != null) 'accessibility_rating': accessibilityRating,
      if (spaciosunessRating != null) 'spaciousness_rating': spaciosunessRating,
    };
  }
}
