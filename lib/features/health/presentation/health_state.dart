part of 'health_bloc.dart';

abstract class HealthState extends Equatable {
  const HealthState();

  @override
  List<Object> get props => [];
}

/// Estado inicial antes de qualquer operação.
class HealthInitial extends HealthState {}

/// Stream conectado — aguardando o primeiro emit de dados.
class HealthLoading extends HealthState {}

/// Lista de registos disponível e atualizada em tempo real.
class HealthEntriesLoaded extends HealthState {
  final List<HealthEntry> entries;

  const HealthEntriesLoaded(this.entries);

  @override
  List<Object> get props => [entries];
}

/// Estado transitório enquanto um novo registo está a ser gravado no Firestore.
class HealthEntryAdding extends HealthState {}

/// Erro na camada de dados (rede, permissão, etc.).
class HealthError extends HealthState {
  final String message;

  const HealthError(this.message);

  @override
  List<Object> get props => [message];
}
