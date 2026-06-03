abstract class CrowdsourceState {}

class CrowdsourceInitial extends CrowdsourceState {}

class CrowdsourceLoading extends CrowdsourceState {}

class CrowdsourceSuccess extends CrowdsourceState {}

class CrowdsourceError extends CrowdsourceState {
  final String message;

  CrowdsourceError(this.message);
}
