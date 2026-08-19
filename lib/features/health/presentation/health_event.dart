part of 'health_bloc.dart';

abstract class HealthEvent extends Equatable {
  const HealthEvent();

  @override
  List<Object> get props => [];
}

/// Carrega a lista de registos de saúde do utilizador.
class WatchHealthEntries extends HealthEvent {
  const WatchHealthEntries();

  @override
  List<Object> get props => [];
}

/// Altera a data atual visualizada no histórico.
class ChangeHealthDate extends HealthEvent {
  final DateTime date;
  const ChangeHealthDate({required this.date});

  @override
  List<Object> get props => [date];
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
  const DeleteHealthEntry({required this.docId});

  @override
  List<Object> get props => [docId];
}

/// Atualiza um registo clínico existente.
class UpdateHealthEntry extends HealthEvent {
  final HealthEntry entry;
  const UpdateHealthEntry(this.entry);

  @override
  List<Object> get props => [entry];
}
