import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:viva_livre_app/features/ratings/domain/entities/bathroom_review.dart';
import 'package:viva_livre_app/features/ratings/domain/repositories/i_rating_repository.dart';

part 'rating_event.dart';
part 'rating_state.dart';

/// BLoC para gerenciar ratings e reviews
class RatingBloc extends Bloc<RatingEvent, RatingState> {
  final IRatingRepository _ratingRepository;

  RatingBloc({required IRatingRepository ratingRepository})
      : _ratingRepository = ratingRepository,
        super(const RatingInitial()) {
    on<LoadBathroomReviews>(_onLoadBathroomReviews);
    on<LoadBathroomRatingStats>(_onLoadBathroomRatingStats);
    on<CreateReview>(_onCreateReview);
    on<UpdateReview>(_onUpdateReview);
    on<DeleteReview>(_onDeleteReview);
    on<VoteHelpful>(_onVoteHelpful);
  }

  /// Carrega reviews de um banheiro
  Future<void> _onLoadBathroomReviews(
    LoadBathroomReviews event,
    Emitter<RatingState> emit,
  ) async {
    emit(const RatingLoading());

    try {
      final result = await _ratingRepository.getReviewsByBathroom(
        bathroomId: event.bathroomId,
        sort: event.sort,
        limit: event.limit,
        offset: event.offset,
      );

      final reviews = result['reviews'] as List<BathroomReview>;
      final total = result['total'] as int;
      final averageRating = (result['average_rating'] as num).toDouble();

      emit(BathroomReviewsLoaded(
        reviews: reviews,
        total: total,
        averageRating: averageRating,
      ));
    } catch (e) {
      emit(RatingError('Não foi possível carregar os reviews. Verifique a sua ligação.'));
    }
  }

  /// Carrega estatísticas de ratings
  Future<void> _onLoadBathroomRatingStats(
    LoadBathroomRatingStats event,
    Emitter<RatingState> emit,
  ) async {
    emit(const RatingLoading());

    try {
      final stats = await _ratingRepository.getBathroomRatingStats(event.bathroomId);
      emit(BathroomRatingStatsLoaded(stats));
    } catch (e) {
      emit(RatingError('Não foi possível carregar as estatísticas.'));
    }
  }

  /// Cria uma nova avaliação
  Future<void> _onCreateReview(
    CreateReview event,
    Emitter<RatingState> emit,
  ) async {
    final previousState = state;
    emit(const ReviewAdding());

    try {
      final review = await _ratingRepository.createReview(
        bathroomId: event.bathroomId,
        rating: event.rating,
        title: event.title,
        comment: event.comment,
        cleanlinessRating: event.cleanlinessRating,
        accessibilityRating: event.accessibilityRating,
        spaciosunessRating: event.spaciosunessRating,
      );

      emit(ReviewCreated(review));

      // Recarregar reviews após criação
      add(LoadBathroomReviews(bathroomId: event.bathroomId));
    } on DioException catch (e) {
      String errorMessage = 'Não foi possível guardar a avaliação. Verifique a sua ligação.';
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data is Map && e.response?.data['error'] != null) {
          errorMessage = e.response?.data['error'];
        }
      }
      emit(RatingError(errorMessage));
      if (previousState is BathroomReviewsLoaded) {
        emit(previousState);
      }
    } catch (e) {
      emit(RatingError('Erro inesperado: $e'));
      if (previousState is BathroomReviewsLoaded) {
        emit(previousState);
      }
    }
  }

  /// Atualiza uma avaliação
  Future<void> _onUpdateReview(
    UpdateReview event,
    Emitter<RatingState> emit,
  ) async {
    final previousState = state;
    emit(const ReviewUpdating());

    try {
      final review = await _ratingRepository.updateReview(
        reviewId: event.reviewId,
        rating: event.rating,
        title: event.title,
        comment: event.comment,
        cleanlinessRating: event.cleanlinessRating,
        accessibilityRating: event.accessibilityRating,
        spaciosunessRating: event.spaciosunessRating,
      );

      emit(ReviewUpdated(review));
    } catch (e) {
      emit(RatingError('Não foi possível atualizar a avaliação.'));
      if (previousState is BathroomReviewsLoaded) {
        emit(previousState);
      }
    }
  }

  /// Deleta uma avaliação
  Future<void> _onDeleteReview(
    DeleteReview event,
    Emitter<RatingState> emit,
  ) async {
    final previousState = state;
    emit(const ReviewDeleting());

    try {
      await _ratingRepository.deleteReview(event.reviewId);
      emit(ReviewDeleted(event.reviewId));
    } catch (e) {
      emit(RatingError('Não foi possível eliminar a avaliação.'));
      if (previousState is BathroomReviewsLoaded) {
        emit(previousState);
      }
    }
  }

  /// Vota se uma avaliação foi útil
  Future<void> _onVoteHelpful(
    VoteHelpful event,
    Emitter<RatingState> emit,
  ) async {
    final previousState = state;
    emit(const VotingHelpful());

    try {
      final result = await _ratingRepository.voteHelpful(
        reviewId: event.reviewId,
        isHelpful: event.isHelpful,
      );

      emit(HelpfulVoteRecorded(
        helpfulCount: result['helpful_count'] ?? 0,
        unhelpfulCount: result['unhelpful_count'] ?? 0,
      ));

      if (previousState is BathroomReviewsLoaded) {
        final updatedReviews = previousState.reviews.map((r) {
          if (r.id == event.reviewId) {
            return BathroomReview(
              id: r.id,
              bathroomId: r.bathroomId,
              userId: r.userId,
              rating: r.rating,
              title: r.title,
              comment: r.comment,
              cleanlinessRating: r.cleanlinessRating,
              accessibilityRating: r.accessibilityRating,
              spaciosunessRating: r.spaciosunessRating,
              helpfulCount: result['helpful_count'] ?? 0,
              unhelpfulCount: result['unhelpful_count'] ?? 0,
              status: r.status,
              photos: r.photos,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
              userName: r.userName,
              userAvatar: r.userAvatar,
            );
          }
          return r;
        }).toList();

        emit(BathroomReviewsLoaded(
          reviews: updatedReviews,
          total: previousState.total,
          averageRating: previousState.averageRating,
        ));
      }
    } catch (e) {
      emit(RatingError('Não foi possível registar o voto.'));
      if (previousState is BathroomReviewsLoaded) {
        emit(previousState);
      }
    }
  }
}
