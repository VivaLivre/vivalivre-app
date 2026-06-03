import 'package:viva_livre_app/features/ratings/data/datasources/rating_remote_datasource.dart';
import 'package:viva_livre_app/features/ratings/data/models/bathroom_review_model.dart';
import 'package:viva_livre_app/features/ratings/domain/entities/bathroom_review.dart';
import 'package:viva_livre_app/features/ratings/domain/repositories/i_rating_repository.dart';

/// Implementação do repositório de ratings
class RatingRepositoryImpl implements IRatingRepository {
  final IRatingRemoteDataSource _remoteDataSource;

  RatingRepositoryImpl({required IRatingRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<BathroomReview> createReview({
    required String bathroomId,
    required int rating,
    String? title,
    String? comment,
    int? cleanlinessRating,
    int? accessibilityRating,
    int? spaciosunessRating,
  }) async {
    try {
      final request = CreateReviewRequest(
        rating: rating,
        title: title,
        comment: comment,
        cleanlinessRating: cleanlinessRating,
        accessibilityRating: accessibilityRating,
        spaciosunessRating: spaciosunessRating,
      );

      final result = await _remoteDataSource.createReview(
        bathroomId: bathroomId,
        request: request,
      );

      return result;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BathroomReview> getReviewById(String reviewId) async {
    try {
      return await _remoteDataSource.getReviewById(reviewId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getReviewsByBathroom({
    required String bathroomId,
    String sort = 'recent',
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      return await _remoteDataSource.getReviewsByBathroom(
        bathroomId: bathroomId,
        sort: sort,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BathroomReview> updateReview({
    required String reviewId,
    int? rating,
    String? title,
    String? comment,
    int? cleanlinessRating,
    int? accessibilityRating,
    int? spaciosunessRating,
  }) async {
    try {
      final request = UpdateReviewRequest(
        rating: rating,
        title: title,
        comment: comment,
        cleanlinessRating: cleanlinessRating,
        accessibilityRating: accessibilityRating,
        spaciosunessRating: spaciosunessRating,
      );

      return await _remoteDataSource.updateReview(
        reviewId: reviewId,
        request: request,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      return await _remoteDataSource.deleteReview(reviewId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, int>> voteHelpful({
    required String reviewId,
    required bool isHelpful,
  }) async {
    try {
      return await _remoteDataSource.voteHelpful(
        reviewId: reviewId,
        isHelpful: isHelpful,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BathroomRatingStats> getBathroomRatingStats(String bathroomId) async {
    try {
      return await _remoteDataSource.getBathroomRatingStats(bathroomId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> hasUserReviewedBathroom(String bathroomId) async {
    try {
      return await _remoteDataSource.hasUserReviewedBathroom(bathroomId);
    } catch (e) {
      return false;
    }
  }
}
