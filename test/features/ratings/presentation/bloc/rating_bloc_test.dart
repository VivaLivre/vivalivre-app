import 'package:flutter_test/flutter_test.dart';
import 'package:viva_livre_app/features/ratings/domain/entities/bathroom_review.dart';
import 'package:viva_livre_app/features/ratings/domain/repositories/i_rating_repository.dart';
import 'package:viva_livre_app/features/ratings/presentation/bloc/rating_bloc.dart';

class FakeRatingRepository implements IRatingRepository {
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
    return BathroomReview(
      id: 'review-1',
      bathroomId: bathroomId,
      userId: 'user-1',
      rating: rating,
      title: title,
      comment: comment,
      cleanlinessRating: cleanlinessRating,
      accessibilityRating: accessibilityRating,
      spaciosunessRating: spaciosunessRating,
      helpfulCount: 0,
      unhelpfulCount: 0,
      status: 'approved',
      photos: const [],
      createdAt: DateTime(2026, 5, 13),
      updatedAt: DateTime(2026, 5, 13),
    );
  }

  @override
  Future<void> deleteReview(String reviewId) async {}

  @override
  Future<BathroomRatingStats> getBathroomRatingStats(String bathroomId) async {
    return BathroomRatingStats(
      bathroomId: bathroomId,
      totalReviews: 1,
      averageRating: 4,
      avgCleanliness: 4,
      avgAccessibility: 5,
      avgSpaciosuneness: 3,
      ratingDistribution: const {4: 1},
    );
  }

  @override
  Future<BathroomReview> getReviewById(String reviewId) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getReviewsByBathroom({
    required String bathroomId,
    String sort = 'recent',
    int limit = 10,
    int offset = 0,
  }) async {
    return {
      'reviews': [
        BathroomReview(
          id: 'review-1',
          bathroomId: bathroomId,
          userId: 'user-1',
          rating: 4,
          title: 'Bom',
          comment: 'Limpo e acessivel',
          cleanlinessRating: 4,
          accessibilityRating: 5,
          spaciosunessRating: 3,
          helpfulCount: 1,
          unhelpfulCount: 0,
          status: 'approved',
          photos: const [],
          createdAt: DateTime(2026, 5, 13),
          updatedAt: DateTime(2026, 5, 13),
        ),
      ],
      'total': 1,
      'average_rating': 4.0,
    };
  }

  @override
  Future<bool> hasUserReviewedBathroom(String bathroomId) async => false;

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
    throw UnimplementedError();
  }

  @override
  Future<Map<String, int>> voteHelpful({
    required String reviewId,
    required bool isHelpful,
  }) async {
    return {'helpful_count': 2, 'unhelpful_count': 0};
  }
}

void main() {
  group('RatingBloc', () {
    late RatingBloc bloc;

    setUp(() {
      bloc = RatingBloc(ratingRepository: FakeRatingRepository());
    });

    tearDown(() async {
      await bloc.close();
    });

    test('emits loaded state when bathroom reviews are requested', () async {
      final states = <RatingState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const LoadBathroomReviews(bathroomId: 'bathroom-1'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(states.first, isA<RatingLoading>());
      expect(states.last, isA<BathroomReviewsLoaded>());

      final loaded = states.last as BathroomReviewsLoaded;
      expect(loaded.total, 1);
      expect(loaded.averageRating, 4.0);
      expect(loaded.reviews.first.bathroomId, 'bathroom-1');

      await sub.cancel();
    });

    test('emits stats loaded state when rating stats are requested', () async {
      final states = <RatingState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const LoadBathroomRatingStats('bathroom-1'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(states.first, isA<RatingLoading>());
      expect(states.last, isA<BathroomRatingStatsLoaded>());

      final loaded = states.last as BathroomRatingStatsLoaded;
      expect(loaded.stats.totalReviews, 1);
      expect(loaded.stats.avgAccessibility, 5);

      await sub.cancel();
    });
  });
}
