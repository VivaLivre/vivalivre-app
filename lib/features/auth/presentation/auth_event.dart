part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthAppStarted extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String cpf;
  final String dateOfBirth;
  final String gender;
  final double? weight;
  final double? height;
  final String clinicalCondition;
  final List<String> comorbidities;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.cpf,
    required this.dateOfBirth,
    required this.gender,
    this.weight,
    this.height,
    required this.clinicalCondition,
    required this.comorbidities,
  });

  @override
  List<Object?> get props => [
        name,
        email,
        password,
        cpf,
        dateOfBirth,
        gender,
        weight,
        height,
        clinicalCondition,
        comorbidities,
      ];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthGoogleLoginRequested extends AuthEvent {}

class AuthUserUpdated extends AuthEvent {
  final UserModel user;

  const AuthUserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthOnboardingCompleted extends AuthEvent {}
