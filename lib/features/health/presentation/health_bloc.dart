import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/domain/repositories/i_health_repository.dart';

part 'health_event.dart';
part 'health_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final IHealthRepository _healthRepository;
  DateTime _currentDate = DateTime.now();

  DateTime get currentDate => _currentDate;

  HealthBloc({required IHealthRepository healthRepository})
      : _healthRepository = healthRepository,
        super(HealthInitial()) {
    on<WatchHealthEntries>(_onWatchHealthEntries);
    on<ChangeHealthDate>(_onChangeHealthDate);
    on<AddHealthEntry>(_onAddHealthEntry);
    on<UpdateHealthEntry>(_onUpdateHealthEntry);
    on<DeleteHealthEntry>(_onDeleteHealthEntry);
  }

  /// Carrega a lista de registos do repositório.
  Future<void> _onWatchHealthEntries(
    WatchHealthEntries event,
    Emitter<HealthState> emit,
  ) async {
    emit(HealthLoading());

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_currentDate);
      final entries = await _healthRepository.getEntries(filterDate: dateStr);
      emit(HealthEntriesLoaded(entries));
    } catch (e) {
      emit(const HealthError('Não foi possível carregar os registos. Verifique a sua ligação.'));
    }
  }

  /// Grava um novo registo de saúde.
  Future<void> _onAddHealthEntry(
    AddHealthEntry event,
    Emitter<HealthState> emit,
  ) async {
    final previousState = state;
    final currentEntries = previousState is HealthEntriesLoaded ? previousState.entries : <HealthEntry>[];

    emit(HealthEntryAdding(currentEntries));

    try {
      final newEntry = await _healthRepository.addEntry(event.entry);
      if (previousState is HealthEntriesLoaded) {
        final updatedList = List<HealthEntry>.from(previousState.entries)..insert(0, newEntry);
        updatedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        emit(HealthEntriesLoaded(updatedList));
      } else {
        add(const WatchHealthEntries());
      }
    } catch (e) {
      emit(const HealthError('Não foi possível guardar o registo. Verifique a sua ligação.'));
      if (previousState is HealthEntriesLoaded) {
        emit(previousState);
      }
    }
  }

  /// Atualiza um registo de saúde.
  Future<void> _onUpdateHealthEntry(
    UpdateHealthEntry event,
    Emitter<HealthState> emit,
  ) async {
    final previousState = state;
    final currentEntries = previousState is HealthEntriesLoaded ? previousState.entries : <HealthEntry>[];

    emit(HealthEntryAdding(currentEntries));

    try {
      final updatedEntry = await _healthRepository.updateEntry(event.entry);
      if (previousState is HealthEntriesLoaded) {
        final updatedList = previousState.entries.map((e) {
          return e.id == updatedEntry.id ? updatedEntry : e;
        }).toList();
        updatedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        emit(HealthEntriesLoaded(updatedList));
      } else {
        add(const WatchHealthEntries());
      }
    } catch (e) {
      emit(const HealthError('Não foi possível atualizar o registo. Verifique a sua ligação.'));
      if (previousState is HealthEntriesLoaded) {
        emit(previousState);
      }
    }
  }

  /// Elimina um registo de saúde.
  Future<void> _onDeleteHealthEntry(
    DeleteHealthEntry event,
    Emitter<HealthState> emit,
  ) async {
    final previousState = state;
    try {
      await _healthRepository.deleteEntry(event.docId);
      add(const WatchHealthEntries());
    } catch (e) {
      emit(const HealthError('Não foi possível eliminar o registo. Verifique a sua ligação.'));
      if (previousState is HealthEntriesLoaded) emit(previousState);
    }
  }

  /// Muda a data visualizada e recarrega os dados.
  Future<void> _onChangeHealthDate(
    ChangeHealthDate event,
    Emitter<HealthState> emit,
  ) async {
    _currentDate = event.date;
    add(const WatchHealthEntries());
  }
}
