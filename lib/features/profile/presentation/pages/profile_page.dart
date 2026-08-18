import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';
import 'package:viva_livre_app/core/theme/app_colors.dart';
import 'package:viva_livre_app/features/health/presentation/health_bloc.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/presentation/pages/health_page.dart' show HealthRecord;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {

  bool _isGeneratingPdf = false;

  @override
  bool get wantKeepAlive => true;

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _exportPdfReport() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    // Simulate PDF generation delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isGeneratingPdf = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Relatório PDF exportado com sucesso! Salvo na pasta Downloads.'),
          backgroundColor: AppColors.successText,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: theme.cardColor,
          title: Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Privacidade e LGPD', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Segurança e controle dos seus dados',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                SizedBox(height: 12),
                Text(
                  'No VivaLivre, levamos a sério a Lei Geral de Proteção de Dados (LGPD). Todos os seus registros de saúde, sintomas e urgências são armazenados com criptografia ponta a ponta e nunca são compartilhados sem sua permissão explícita.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                SizedBox(height: 12),
                Text(
                  'Direitos do Usuário:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                SizedBox(height: 6),
                Text(
                  '• Revogação de consentimento a qualquer momento.\n• Acesso completo ao relatório exportável.\n• Exclusão total e definitiva dos dados ao remover sua conta.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendi', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: theme.cardColor,
          title: Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Ajuda e Suporte', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Estamos aqui para ajudar!',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              SizedBox(height: 12),
              Text(
                'Se você tiver dúvidas, sugestões ou problemas técnicos com o VivaLivre, entre em contato através de nossos canais oficiais:',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 18, color: AppColors.lightSubText),
                  SizedBox(width: 8),
                  Text('suporte@vivalivre.org', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 18, color: AppColors.lightSubText),
                  SizedBox(width: 8),
                  Text('0800 123 4567', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final _kBg = theme.scaffoldBackgroundColor;
    final _kBlue = theme.colorScheme.primary;
    final _kText = theme.colorScheme.onSurface;
    final _kSubText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final _kCardBg = isDark ? AppColors.darkSurface : Colors.white;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Perfil',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _kText,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: _kBlue, size: 22),
                        tooltip: 'Editar Perfil',
                        onPressed: () {
                          Navigator.pushNamed(context, '/edit-profile');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── 1. Cabeçalho do Paciente ──
                  Center(
                    child: Column(
                      children: [
                        // Avatar com Foto ou Gradiente
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _kBlue.withValues(alpha: 0.15),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: user?.avatarUrl != null
                                ? Image.network(
                                    user!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person_rounded,
                                        size: 48,
                                        color: AppColors.lightSubText,
                                      );
                                    },
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_kBlue, const Color(0xFF3B82F6)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Nome e Email
                        Text(
                          user?.name ?? 'Usuário',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _kText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: _kSubText),
                        ),
                        const SizedBox(height: 12),
                        // Chip "Paciente DII - Conta Ativa"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.successText.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_rounded, size: 14, color: AppColors.successText),
                              SizedBox(width: 6),
                              Text(
                                'Paciente DII - Conta Ativa',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.successText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── 2. Métricas de Saúde (Altura, Peso, Idade) ──
                  Row(
                    children: [
                      // Altura
                      Expanded(
                        child: _MetricCard(
                          title: 'Altura',
                          value: user?.height != null 
                              ? '${user!.height!.toInt()} cm' 
                              : '--',
                          icon: Icons.height_rounded,
                          color: const Color(0xFF2563EB),
                          cardBg: _kCardBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Peso
                      Expanded(
                        child: _MetricCard(
                          title: 'Peso',
                          value: user?.weight != null 
                              ? '${user!.weight!.toInt()} kg' 
                              : '--',
                          icon: Icons.monitor_weight_outlined,
                          color: const Color(0xFF10B981),
                          cardBg: _kCardBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Idade
                      Expanded(
                        child: _MetricCard(
                          title: 'Idade',
                          value: user?.birthDate != null
                              ? '${_calculateAge(user!.birthDate!)} anos'
                              : '--',
                          icon: Icons.cake_outlined,
                          color: const Color(0xFFF59E0B),
                          cardBg: _kCardBg,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── 2.5 Resumo de Saúde (Dashboard) ──
                  GestureDetector(
                    onTap: () {
                      final healthState = context.read<HealthBloc>().state;
                      final entries = healthState is HealthEntriesLoaded
                          ? healthState.entries
                          : healthState is HealthEntryAdding
                              ? healthState.entries
                              : <HealthEntry>[];
                      final records = entries.map(HealthRecord.fromEntry).toList();
                      Navigator.pushNamed(context, '/health-dashboard', arguments: records);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.bar_chart_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resumo de Saúde',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: _kText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Estatísticas e gráficos dos seus sintomas',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _kSubText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: _kSubText,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 3. Relatório PDF Prominente ──
                  GestureDetector(
                    onTap: _isGeneratingPdf ? null : _exportPdfReport,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _kBlue.withValues(alpha: isDark ? 0.05 : 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isGeneratingPdf
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Relatório de Saúde',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isGeneratingPdf
                                      ? 'Processando e gerando arquivo...'
                                      : 'Exportar histórico de sintomas em PDF',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isGeneratingPdf)
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Configurações',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kSubText, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  _ProfileMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'Privacidade e LGPD',
                    onTap: _showPrivacyDialog,
                    cardBg: _kCardBg,
                  ),
                  _ProfileMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Ajuda e Suporte',
                    onTap: _showHelpSupportDialog,
                    cardBg: _kCardBg,
                  ),
                  _ProfileMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Sair',
                    isDestructive: true,
                    onTap: () {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                    },
                    cardBg: _kCardBg,
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
//  _MetricCard
// ═════════════════════════════════════════════════════════════════════════════

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color cardBg;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.lightSubText,
            ),
          ),
        ],
      ),
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
  final Color cardBg;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.cardBg,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 15),
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

