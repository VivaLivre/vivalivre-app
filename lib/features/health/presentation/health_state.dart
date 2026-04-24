part of 'health_bloc.dart';

abstract class HealthState extends Equatable {
  const HealthState();

  @override
  List<Object> get props => [];
}

class HealthInitial extends HealthState {}

class HealthLoading extends HealthState {}

class HealthEntriesLoaded extends HealthState {
  final List<HealthEntry> entries;

  const HealthEntriesLoaded(this.entries);

  @override
  List<Object> get props => [entries];
}

class HealthEntryAdded extends HealthState {}

class HealthError extends HealthState {
  final String message;

  const HealthError(this.message);

  @override
  List<Object> get props => [message];
}
