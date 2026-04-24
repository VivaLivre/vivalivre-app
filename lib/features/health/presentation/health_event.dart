part of 'health_bloc.dart';

abstract class HealthEvent extends Equatable {
  const HealthEvent();

  @override
  List<Object> get props => [];
}

class AddHealthEntry extends HealthEvent {
  final HealthEntry entry;

  const AddHealthEntry(this.entry);

  @override
  List<Object> get props => [entry];
}

class FetchHealthEntries extends HealthEvent {}
