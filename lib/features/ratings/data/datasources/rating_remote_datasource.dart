import 'package:flutter/foundation.dart';
import 'package:viva_livre_app/core/api/api_client.dart';
import 'package:viva_livre_app/features/ratings/data/models/bathroom_review_model.dart';

/// Datasource remoto para ratings
abstract class IRatingRemoteDataSource {
  Future<BathroomReviewModel> createReview({
    required String bathroomId,
    required CreateReviewRequest request,
  });

  Future<BathroomReviewModel> getReviewById(String reviewId);

  Future<Map<String, dynamic>> getReviewsByBathroom({
    required String bathroomId,
    String sort = 'recent',
    int limit = 10,
    int offset = 0,
  });

  Future<BathroomReviewModel> updateReview({
    required String reviewId,
    required UpdateReviewRequest request,
  });

  Future<void> deleteReview(String reviewId);

  Future<Map<String, int>> voteHelpful({
    required String reviewId,
    required bool isHelpful,
  });

  Future<BathroomRatingStatsModel> getBathroomRatingStats(String bathroomId);

  Future<bool> hasUserReviewedBathroom(String bathroomId);
}

/// Implementação do datasource remoto
class RatingRemoteDataSourceImpl implements IRatingRemoteDataSource {
  final ApiClient _apiClient;

  RatingRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<BathroomReviewModel> createReview({
    required String bathroomId,
    required CreateReviewRequest request,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/bathrooms/$bathroomId/reviews',
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        debugPrint('[RatingDataSource] Review created successfully');
        return BathroomReviewModel.fromJson(response.data);
      }

      throw Exception('Failed to create review');
    } catch (e) {
      debugPrint('[RatingDataSource] Error creating review: $e');
      rethrow;
    }
  }

  @override
  Future<BathroomReviewModel> getReviewById(String reviewId) async {
    try {
      final response = await _apiClient.dio.get('/api/reviews/$reviewId');

      if (response.statusCode == 200) {
        debugPrint('[RatingDataSource] Review fetched successfully');
        return BathroomReviewModel.fromJson(response.data);
      }

      throw Exception('Failed to get review');
    } catch (e) {
      debugPrint('[RatingDataSource] Error getting review: $e');
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
      final response = await _apiClient.dio.get(
        '/api/bathrooms/$bathroomId/reviews',
        queryParameters: {
          'sort': sort,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('[RatingDataSource] Reviews fetched successfully');
        
        final reviews = (response.data['reviews'] as List)
            .map((json) => BathroomReviewModel.fromJson(json))
            .toList();

        return {
          'reviews': reviews,
          'total': response.data['total'] as int,
          'average_rating': response.data['average_rating'] as double,
        };
      }

      throw Exception('Failed to get reviews');
    } catch (e) {
      debugPrint('[RatingDataSource] Error getting reviews: $e');
      rethrow;
    }
  }

  @override
  Future<BathroomReviewModel> updateReview({
    required String reviewId,
    required UpdateReviewRequest request,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/reviews/$reviewId',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        debugPrint('[RatingDataSource] Review updated successfully');
        return BathroomReviewModel.fromJson(response.data);
      }

      throw Exception('Failed to update review');
    } catch (e) {
      debugPrint('[RatingDataSource] Error updating review: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      final response = await _apiClient.dio.delete('/api/reviews/$reviewId');

      if (response.statusCode == 204) {
        debugPrint('[RatingDataSource] Review deleted successfully');
        return;
      }

      throw Exception('Failed to delete review');
    } catch (e) {
      debugPrint('[RatingDataSource] Error deleting review: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, int>> voteHelpful({
    required String reviewId,
    required bool isHelpful,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/reviews/$reviewId/helpful',
        data: {'is_helpful': isHelpful},
      );

      if (response.statusCode == 200) {
        debugPrint('[RatingDataSource] Vote recorded successfully');
        return {
          'helpful_count': response.data['helpful_count'] as int,
          'unhelpful_count': response.data['unhelpful_count'] as int,
        };
      }

      throw Exception('Failed to vote');
    } catch (e) {
      debugPrint('[RatingDataSource] Error voting: $e');
      rethrow;
    }
  }

  @override
  Future<BathroomRatingStatsModel> getBathroomRatingStats(
    String bathroomId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/bathrooms/$bathroomId/rating-stats',
      );

      if (response.statusCode == 200) {
        debugPrint('[RatingDataSource] Rating stats fetched successfully');
        return BathroomRatingStatsModel.fromJson(response.data);
      }

      throw Exception('Failed to get rating stats');
    } catch (e) {
      debugPrint('[RatingDataSource] Error getting rating stats: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasUserReviewedBathroom(String bathroomId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/bathrooms/$bathroomId/reviews',
        queryParameters: {'limit': 1},
      );

      if (response.statusCode == 200) {
        // Verificar se o utilizador tem um review neste banheiro
        // Esta lógica seria melhor implementada no backend
        debugPrint('[RatingDataSource] Checked user review status');
        return false; // TODO: Implementar verificação real
      }

      return false;
    } catch (e) {
      debugPrint('[RatingDataSource] Error checking review: $e');
      return false;
    }
  }
}
