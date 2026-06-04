import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
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
    final user = await _authRepository.checkAuth();
    if (user != null) {
      emit(AuthAuthenticated(user));
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
      emit(AuthError(_authErrorMessage(e, isRegister: false)));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.register(
        event.name,
        event.email,
        event.password,
      );
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Não foi possível criar a conta.'));
      }
    } catch (e) {
      emit(AuthError(_authErrorMessage(e, isRegister: true)));
    }
  }

  String _authErrorMessage(Object error, {required bool isRegister}) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      final serverMessage = responseData is Map<String, dynamic>
          ? responseData['error'] as String?
          : null;

      if (statusCode == 409 && isRegister) {
        return serverMessage ?? 'Este email já foi utilizado.';
      }

      if (statusCode == 400) {
        return serverMessage ?? 'Verifique os dados informados.';
      }

      if (statusCode == 401) {
        return 'Credenciais inválidas.';
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Tempo esgotado ao conectar ao servidor. Verifique se a API está acessível na rede.';
      }

      if (error.type == DioExceptionType.connectionError ||
          error.error is SocketException) {
        return 'Não foi possível conectar ao servidor. Verifique o IP, a porta e a rede do dispositivo.';
      }

      if (statusCode != null && statusCode >= 500) {
        return 'Erro interno no servidor. Tente novamente em instantes.';
      }
    }

    return isRegister
        ? 'Não foi possível criar a conta. Tente novamente.'
        : 'Erro ao entrar. Verifique sua conexão.';
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
