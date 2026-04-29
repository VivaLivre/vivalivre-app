import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/repositories/auth_repository.dart';
import '../../../core/models/user_model.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
 
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthAppStarted>(_onAuthAppStarted);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthAppStarted(
    AuthAppStarted event,
    Emitter<AuthState> emit,
  ) async {
    final authenticated = await _authRepository.isAuthenticated();
    if (authenticated) {
      // For now, we don't have a /me endpoint, so we might need to store user data in storage too
      // or fetch it. Let's assume we store basic info.
      // emit(AuthAuthenticated(user)); 
      emit(AuthUnauthenticated()); // Temporary until we handle persistence of user info
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(event.email, event.password);
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Credenciais inválidas.'));
      }
    } catch (e) {
      emit(const AuthError('Erro ao entrar. Verifique sua conexão.'));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.register(event.name, event.email, event.password);
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Não foi possível criar a conta.'));
      }
    } catch (e) {
      emit(const AuthError('Erro ao registrar. Email já pode estar em uso.'));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
