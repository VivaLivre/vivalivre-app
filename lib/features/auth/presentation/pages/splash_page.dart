import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';
import 'package:viva_livre_app/features/auth/data/repositories/onboarding_repository.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    // Delay to show the splash screen slightly
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final onboardingRepository = context.read<OnboardingRepository>();
    final hasSeenOnboarding = await onboardingRepository.hasSeenOnboarding();

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      // Dispatch the AuthAppStarted event to check authentication status
      context.read<AuthBloc>().add(AuthAppStarted());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to authentication state changes
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.user.clinicalCondition == null || state.user.clinicalCondition!.isEmpty) {
            Navigator.pushReplacementNamed(context, '/complete-profile');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else if (state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(context, '/login');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'VivaLivre',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
