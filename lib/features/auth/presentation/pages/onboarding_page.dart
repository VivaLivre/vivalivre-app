import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viva_livre_app/features/auth/data/repositories/onboarding_repository.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () async {
                  await context.read<OnboardingRepository>().setOnboardingSeen();
                  if (!mounted) return;
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Pular', style: TextStyle(color: Colors.grey)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: const [
                  OnboardingCard(
                    icon: Icons.map_rounded,
                    title: 'Mapa de Banheiros',
                    description:
                        'Encontre banheiros públicos e seguros próximos a você com rapidez e facilidade.',
                    gradientColors: [Color(0xFFE0E7FF), Color(0xFFDBEAFE)], // Indigo-100 to Blue-100
                  ),
                  OnboardingCard(
                    icon: Icons.health_and_safety_rounded,
                    title: 'Controle de Saúde',
                    description:
                        'Gerencie suas medicações, registre sintomas e acompanhe a evolução do seu tratamento.',
                    gradientColors: [Color(0xFFDCFCE7), Color(0xFFD1FAE5)], // Green-100 to Emerald-100
                  ),
                  OnboardingCard(
                    icon: Icons.people_alt_rounded,
                    title: 'Comunidade',
                    description:
                        'Compartilhe experiências, tire dúvidas e conecte-se com outras pessoas que te entendem.',
                    gradientColors: [Color(0xFFF3E8FF), Color(0xFFFAE8FF)], // Purple-100 to Fuchsia-100
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      3,
                      (index) => buildDot(index, context),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_currentPage == 2) {
                        await context.read<OnboardingRepository>().setOnboardingSeen();
                        if (!mounted) return;
                        Navigator.of(context).pushReplacementNamed('/login');
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(_currentPage == 2 ? 'Começar' : 'Avançar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AnimatedContainer buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _currentPage == index
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      ),
    );
  }
}

class OnboardingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;

  const OnboardingCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeGradient = isDark 
        ? [Theme.of(context).colorScheme.primary.withValues(alpha: 0.15), Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)]
        : gradientColors;
    final activeShadowColor = isDark
        ? Colors.black.withValues(alpha: 0.2)
        : gradientColors.first.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: activeGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: activeShadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 100,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.6 : 0.8),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface, // slate-800
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), // slate-500
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
