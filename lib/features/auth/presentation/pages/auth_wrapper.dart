import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';
import 'package:viva_livre_app/features/auth/presentation/pages/login_page.dart';
import 'package:viva_livre_app/features/home/presentation/pages/main_shell.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const _LoadingScreen();
        }

        if (state is AuthAuthenticated) {
          return const MainShell();
        }

        return const LoginPage();
      },
    );
  }
}

/// Tela de loading exibida enquanto o estado de autenticação é resolvido.
/// Garante que nenhuma rota protegida seja renderizada prematuramente.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2563EB),
          strokeWidth: 3,
        ),
      ),
    );
  }
}
