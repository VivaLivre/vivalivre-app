import 'package:viva_livre_app/features/ratings/domain/entities/bathroom_review.dart';

/// Interface do repositório de ratings
abstract class IRatingRepository {
  /// Cria uma nova avaliação de banheiro
  /// Lança [Exception] em caso de falha
  Future<BathroomReview> createReview({
    required String bathroomId,
    required int rating,
    String? title,
    String? comment,
    int? cleanlinessRating,
    int? accessibilityRating,
    int? spaciosunessRating,
  });

  /// Obtém uma avaliação pelo ID
  Future<BathroomReview> getReviewById(String reviewId);

  /// Lista avaliações de um banheiro
  /// [sort] pode ser: 'recent', 'helpful', 'rating'
  Future<Map<String, dynamic>> getReviewsByBathroom({
    required String bathroomId,
    String sort = 'recent',
    int limit = 10,
    int offset = 0,
  });

  /// Atualiza uma avaliação
  Future<BathroomReview> updateReview({
    required String reviewId,
    int? rating,
    String? title,
    String? comment,
    int? cleanlinessRating,
    int? accessibilityRating,
    int? spaciosunessRating,
  });

  /// Deleta uma avaliação
  Future<void> deleteReview(String reviewId);

  /// Vota se uma avaliação foi útil
  Future<Map<String, int>> voteHelpful({
    required String reviewId,
    required bool isHelpful,
  });

  /// Obtém estatísticas de ratings de um banheiro
  Future<BathroomRatingStats> getBathroomRatingStats(String bathroomId);

  /// Verifica se o utilizador já avaliou o banheiro
  Future<bool> hasUserReviewedBathroom(String bathroomId);
}
