import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/domain/repositories/i_health_repository.dart';

part 'health_event.dart';
part 'health_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final IHealthRepository _healthRepository;

  /// Subscription ao Stream do Firestore — cancelada em [close()].
  StreamSubscription<List<HealthEntry>>? _entriesSubscription;

  HealthBloc({required IHealthRepository healthRepository})
      : _healthRepository = healthRepository,
        super(HealthInitial()) {
    on<WatchHealthEntries>(_onWatchHealthEntries);
    on<_HealthEntriesUpdated>(_onHealthEntriesUpdated);
    on<AddHealthEntry>(_onAddHealthEntry);
  }

  /// Inicia (ou reinicia) a escuta do Stream de registos do Firestore.
  Future<void> _onWatchHealthEntries(
    WatchHealthEntries event,
    Emitter<HealthState> emit,
  ) async {
    emit(HealthLoading());

    // Cancela qualquer subscription anterior antes de criar uma nova.
    await _entriesSubscription?.cancel();

    _entriesSubscription = _healthRepository
        .watchEntries(event.userId)
        .listen(
          (entries) => add(_HealthEntriesUpdated(entries)),
          onError: (Object e) => add(
            const _HealthEntriesUpdated([]),
          ),
        );
  }

  /// Recebe as atualizações do Stream e emite o novo estado.
  void _onHealthEntriesUpdated(
    _HealthEntriesUpdated event,
    Emitter<HealthState> emit,
  ) {
    emit(HealthEntriesLoaded(event.entries));
  }

  /// Grava um novo registo no Firestore.
  Future<void> _onAddHealthEntry(
    AddHealthEntry event,
    Emitter<HealthState> emit,
  ) async {
    // Guarda o estado carregado para restaurar em caso de erro.
    final previousState = state;

    emit(HealthEntryAdding());

    try {
      await _healthRepository.addEntry(event.entry);
      // Não precisamos emitir HealthEntriesLoaded aqui —
      // o Stream do Firestore dispara automaticamente com o novo documento.
    } catch (e) {
      emit(const HealthError('Não foi possível guardar o registo. Verifique a sua ligação.'));
      // Restaura o estado anterior para que a UI não quebre.
      if (previousState is HealthEntriesLoaded) {
        emit(previousState);
      }
    }
  }

  @override
  Future<void> close() async {
    await _entriesSubscription?.cancel();
    return super.close();
  }
}
