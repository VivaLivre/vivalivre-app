import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_crowdsource_repository.dart';
import 'crowdsource_event.dart';
import 'crowdsource_state.dart';

class CrowdsourceBloc extends Bloc<CrowdsourceEvent, CrowdsourceState> {
  final ICrowdsourceRepository repository;

  CrowdsourceBloc({required this.repository}) : super(CrowdsourceInitial()) {
    on<SubmitReportEvent>(_onSubmitReport);
    on<SubmitSuggestionEvent>(_onSubmitSuggestion);
  }

  Future<void> _onSubmitReport(
      SubmitReportEvent event, Emitter<CrowdsourceState> emit) async {
    emit(CrowdsourceLoading());
    try {
      await repository.submitReport(
          event.bathroomId, event.reason, event.description);
      emit(CrowdsourceSuccess());
    } catch (e) {
      emit(CrowdsourceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSubmitSuggestion(
      SubmitSuggestionEvent event, Emitter<CrowdsourceState> emit) async {
    emit(CrowdsourceLoading());
    try {
      await repository.submitSuggestion(event.bathroomId, event.suggestedUpdates);
      emit(CrowdsourceSuccess());
    } catch (e) {
      emit(CrowdsourceError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
