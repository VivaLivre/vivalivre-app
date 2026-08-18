part of 'health_bloc.dart';

abstract class HealthEvent extends Equatable {
  const HealthEvent();

  @override
  List<Object> get props => [];
}

/// Carrega a lista de registos de saúde do utilizador.
class WatchHealthEntries extends HealthEvent {
  final String userId;
  const WatchHealthEntries(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Altera a data atual visualizada no histórico.
class ChangeHealthDate extends HealthEvent {
  final DateTime date;
  final String userId;
  const ChangeHealthDate({required this.date, required this.userId});

  @override
  List<Object> get props => [date, userId];
}

/// Adiciona um novo registo clínico.
class AddHealthEntry extends HealthEvent {
  final HealthEntry entry;
  const AddHealthEntry(this.entry);

  @override
  List<Object> get props => [entry];
}

/// Elimina um registo clínico pelo seu ID.
class DeleteHealthEntry extends HealthEvent {
  final String docId;
  final String userId;
  const DeleteHealthEntry({required this.docId, required this.userId});

  @override
  List<Object> get props => [docId, userId];
}
