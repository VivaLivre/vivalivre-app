import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/domain/repositories/i_health_repository.dart';

part 'health_event.dart';
part 'health_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final IHealthRepository _healthRepository;

  HealthBloc({required IHealthRepository healthRepository})
      : _healthRepository = healthRepository,
        super(HealthInitial()) {
    on<WatchHealthEntries>(_onWatchHealthEntries);
    on<AddHealthEntry>(_onAddHealthEntry);
    on<DeleteHealthEntry>(_onDeleteHealthEntry);
  }

  /// Carrega a lista de registos do repositório.
  Future<void> _onWatchHealthEntries(
    WatchHealthEntries event,
    Emitter<HealthState> emit,
  ) async {
    emit(HealthLoading());

    try {
      final entries = await _healthRepository.getEntries(event.userId, filterDate: 'today');
      emit(HealthEntriesLoaded(entries));
    } catch (e) {
      emit(const HealthError('Não foi possível carregar os registos. Verifique a sua ligação.'));
    }
  }

  /// Grava um novo registo de saúde.
  /// Após sucesso, recarrega a lista imediatamente.
  Future<void> _onAddHealthEntry(
    AddHealthEntry event,
    Emitter<HealthState> emit,
  ) async {
    final previousState = state;

    emit(HealthEntryAdding());

    try {
      await _healthRepository.addEntry(event.entry);
      // ✅ Recarregar lista imediatamente após inserção bem-sucedida
      add(WatchHealthEntries(event.entry.userId.toString()));
    } catch (e) {
      emit(const HealthError('Não foi possível guardar o registo. Verifique a sua ligação.'));
      if (previousState is HealthEntriesLoaded) {
        emit(previousState);
      }
    }
  }

  /// Elimina um registo de saúde.
  /// Após sucesso, recarrega a lista imediatamente.
  Future<void> _onDeleteHealthEntry(
    DeleteHealthEntry event,
    Emitter<HealthState> emit,
  ) async {
    final previousState = state;
    try {
      await _healthRepository.deleteEntry(event.docId, event.userId);
      // ✅ Recarregar lista imediatamente após deleção bem-sucedida
      add(WatchHealthEntries(event.userId));
    } catch (e) {
      emit(const HealthError('Não foi possível eliminar o registo. Verifique a sua ligação.'));
      if (previousState is HealthEntriesLoaded) emit(previousState);
    }
  }
}
