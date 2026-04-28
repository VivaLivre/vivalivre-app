part of 'health_bloc.dart';

abstract class HealthEvent extends Equatable {
  const HealthEvent();

  @override
  List<Object> get props => [];
}

/// Inicia a escuta do Stream de registos do Firestore para o [userId].
class WatchHealthEntries extends HealthEvent {
  final String userId;
  const WatchHealthEntries(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Evento interno disparado pelo Stream quando os dados mudam no Firestore.
/// Não deve ser disparado diretamente pela UI.
class _HealthEntriesUpdated extends HealthEvent {
  final List<HealthEntry> entries;
  const _HealthEntriesUpdated(this.entries);

  @override
  List<Object> get props => [entries];
}

/// Adiciona um novo registo clínico no Firestore.
class AddHealthEntry extends HealthEvent {
  final HealthEntry entry;
  const AddHealthEntry(this.entry);

  @override
  List<Object> get props => [entry];
}
