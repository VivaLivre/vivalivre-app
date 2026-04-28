import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:viva_livre_app/features/auth/presentation/pages/login_page.dart';
import 'package:viva_livre_app/features/home/presentation/pages/main_shell.dart';

/// Guarda de rota raiz do aplicativo.
///
/// Escuta [FirebaseAuth.instance.authStateChanges()] e decide qual tela
/// mostrar com base no estado de autenticação, eliminando qualquer
/// possibilidade de crash por UID nulo (Null Safety).
///
/// Fluxo:
///   • Carregando  → [_LoadingScreen] (spinner centralizado)
///   • Logado      → [MainShell]
///   • Deslogado   → [LoginPage]
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ── Aguardando a resolução inicial do estado ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // ── Erro inesperado no stream ──
        if (snapshot.hasError) {
          return const _LoadingScreen();
        }

        // ── Utilizador autenticado → shell principal ──
        if (snapshot.hasData && snapshot.data != null) {
          return const MainShell();
        }

        // ── Sem sessão ativa → ecrã de login ──
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
