import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viva_livre_app/features/auth/presentation/pages/auth_wrapper.dart';
import 'package:viva_livre_app/features/auth/presentation/pages/splash_page.dart';
import 'package:viva_livre_app/features/auth/presentation/pages/onboarding_page.dart';
import 'package:viva_livre_app/features/auth/presentation/pages/login_page.dart';
import 'package:viva_livre_app/features/auth/presentation/pages/register_page.dart';
import 'package:viva_livre_app/features/home/presentation/pages/main_shell.dart';
import 'package:viva_livre_app/features/health/presentation/pages/health_dashboard_page.dart';
import 'package:viva_livre_app/features/health/presentation/pages/add_health_entry_page.dart';
import 'package:viva_livre_app/features/health/presentation/pages/health_page.dart';

class App extends StatelessWidget {
  final FirebaseAuth firebaseAuth;

  const App({super.key, required this.firebaseAuth});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VivaLivre',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          surface: const Color(0xFFF8FAFC),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      // ── Rota raiz protegida pelo AuthWrapper ──
      // AuthWrapper escuta FirebaseAuth.authStateChanges() e encaminha
      // para MainShell (logado) ou LoginPage (deslogado) sem crash de UID nulo.
      home: const AuthWrapper(),
      routes: {
        '/splash': (_) => const SplashPage(),
        '/onboarding': (_) => const OnboardingPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const MainShell(),
        '/health-dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as List<HealthRecord>? ?? [];
          return HealthDashboardPage(records: args);
        },
        '/add-health-entry': (_) => const AddHealthEntryPage(),
      },
    );
  }
}
