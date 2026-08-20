import 'package:flutter/material.dart';
import 'package:viva_livre_app/features/auth/presentation/pages/splash_page.dart';
import 'package:viva_livre_app/features/auth/presentation/pages/onboarding_page.dart';
import 'package:viva_livre_app/features/auth/presentation/pages/login_page.dart';
import 'package:viva_livre_app/features/auth/presentation/pages/register_page.dart';
import 'package:viva_livre_app/features/home/presentation/pages/main_shell.dart';
import 'package:viva_livre_app/features/health/presentation/pages/health_dashboard_page.dart';
import 'package:viva_livre_app/features/health/presentation/pages/add_health_entry_page.dart';
import 'package:viva_livre_app/features/health/presentation/pages/health_page.dart';
import 'package:viva_livre_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:viva_livre_app/features/profile/presentation/pages/complete_profile_page.dart';
import 'package:viva_livre_app/features/profile/presentation/pages/complete_profile_page.dart';
import 'package:viva_livre_app/core/theme/app_theme.dart';
import 'package:viva_livre_app/core/theme/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          title: 'VivaLivre',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          navigatorKey: globalNavigatorKey,
      // ── Rota raiz protegida pelo SplashPage ──
      // SplashPage verifica onboarding, dispara a autenticação e
      // encaminha para /home (MainShell), /login ou /onboarding.
      home: const SplashPage(),
      routes: {
        '/onboarding': (_) => const OnboardingPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const MainShell(),
        '/health-dashboard': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as List<HealthRecord>? ??
              [];
          return HealthDashboardPage(records: args);
        },
        '/add-health-entry': (_) => const AddHealthEntryPage(),
        '/edit-profile': (_) => const EditProfilePage(),
        '/complete-profile': (_) => const CompleteProfilePage(),
      },
    );
      },
    );
  }
}
