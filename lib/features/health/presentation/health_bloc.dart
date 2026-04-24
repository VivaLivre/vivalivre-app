import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/data/repositories/health_repository.dart';

part 'health_event.dart';
part 'health_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final HealthRepository _healthRepository;

  HealthBloc({required HealthRepository healthRepository})
    : _healthRepository = healthRepository,
      super(HealthInitial()) {
    on<FetchHealthEntries>(_onFetchHealthEntries);
    on<AddHealthEntry>(_onAddHealthEntry);
  }

  Future<void> _onFetchHealthEntries(
    FetchHealthEntries event,
    Emitter<HealthState> emit,
  ) async {
    emit(HealthLoading());
    try {
      final entries = await _healthRepository.getHealthEntries();
      emit(HealthEntriesLoaded(entries));
    } catch (e) {
      emit(HealthError('Failed to load entries. Please try again.'));
    }
  }

  Future<void> _onAddHealthEntry(
    AddHealthEntry event,
    Emitter<HealthState> emit,
  ) async {
    try {
      await _healthRepository.addHealthEntry(event.entry);
      // After adding, refresh the list to show the new entry
      add(FetchHealthEntries()); // Re-fetch entries to update the list
      emit(HealthEntryAdded()); // Indicate that an entry was added successfully
    } catch (e) {
      emit(HealthError('Failed to add entry. Please try again.'));
    }
  }
}
