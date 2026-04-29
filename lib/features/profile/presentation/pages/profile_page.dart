import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {

  // ── Paleta de Cores (Design System Médico) ──
  static const Color _kBg = Color(0xFFF8FAFC);
  static const Color _kBlue = Color(0xFF2563EB);
  static const Color _kGreenText = Color(0xFF10B981);
  static const Color _kGreenBg = Color(0xFFD1FAE5);
  static const Color _kText = Color(0xFF1E293B);
  static const Color _kSubText = Color(0xFF64748B);
  static const Color _kCardBorder = Color(0xFFF1F5F9);

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 1. Cabeçalho do Paciente ──
                  Center(
                    child: Column(
                      children: [
                        // Avatar com Foto ou Gradiente
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [_kBlue, Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kBlue.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person_rounded, size: 44, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        // Nome e Email
                        Text(
                          user?.name ?? 'Usuário',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _kText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(fontSize: 14, color: _kSubText),
                        ),
                        const SizedBox(height: 12),
                        // Chip "Paciente DII - Conta Ativa"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _kGreenBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_rounded, size: 14, color: _kGreenText),
                              SizedBox(width: 6),
                              Text(
                                'Paciente DII - Conta Ativa',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _kGreenText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  // ... remaining UI ...

              // ── 2. Card de Resumo Clínico ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kCardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Coluna Esquerda: Urgências
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.bolt_rounded, color: _kBlue, size: 24),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '12',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kText),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Urgências',
                            style: TextStyle(fontSize: 13, color: _kSubText, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    // Divisória Vertical
                    Container(
                      height: 50,
                      width: 1,
                      color: _kCardBorder,
                    ),
                    // Coluna Direita: Sintomas
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.healing_rounded, color: Color(0xFFF59E0B), size: 24),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '4',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kText),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Sintomas',
                            style: TextStyle(fontSize: 13, color: _kSubText, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── 3. Agrupamento de Menus ──

              // Secção: Gestão Clínica
              const Text(
                'Gestão Clínica',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kSubText),
              ),
              const SizedBox(height: 12),
              _ProfileMenuItem(icon: Icons.tune_rounded, title: 'Preferências de Crise', onTap: () {}),
              _ProfileMenuItem(icon: Icons.description_outlined, title: 'Exportar Relatório PDF', onTap: () {}),

              const SizedBox(height: 24),

              // Secção: Conta e Segurança
              const Text(
                'Conta e Segurança',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kSubText),
              ),
              const SizedBox(height: 12),
              _ProfileMenuItem(icon: Icons.person_outline_rounded, title: 'Editar Perfil', onTap: () {}),
              _ProfileMenuItem(icon: Icons.shield_outlined, title: 'Privacidade e LGPD', onTap: () {}),
              _ProfileMenuItem(icon: Icons.help_outline_rounded, title: 'Ajuda e Suporte', onTap: () {}),

              const SizedBox(height: 32),

              // ── 4. Ação de Logout ──
              _ProfileMenuItem(
                icon: Icons.logout_rounded,
                title: 'Sair',
                isDestructive: true,
                onTap: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  },
);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  _ProfileMenuItem
// ═════════════════════════════════════════════════════════════════════════════

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade600 : const Color(0xFF334155);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 15),
        ),
        trailing: isDestructive
            ? null
            : const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
