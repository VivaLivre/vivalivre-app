import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';

class CartaoDIIPage extends StatelessWidget {
  const CartaoDIIPage({super.key});

  // ── Paleta de Cores (Design System Médico) ──

  Future<void> _openLaudo(String? laudoUrl) async {
    if (laudoUrl == null || laudoUrl.isEmpty) {
      return;
    }

    final uri = Uri.parse(laudoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Text('Usuário não autenticado', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            ),
          );
        }

        final user = state.user;
        const String? cid = null;
        const String? laudoUrl = null;
        final String userName = user.name;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final alertBg = isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);
        final alertText = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
        final alertBorder = isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Icon(Icons.badge_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VIVALIVRE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Cartão de Identificação DII',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Cartão de Identificação (Crachá) ──
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho do Cartão
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.medical_information_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'CARTÃO DE IDENTIFICAÇÃO DII',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        Divider(color: Theme.of(context).dividerColor),
                        const SizedBox(height: 20),

                        // Nome do Titular
                        Text(
                          'TITULAR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // CID
                        Text(
                          'CID',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cid ?? 'Não informado',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cid != null ? Theme.of(context).colorScheme.onSurface : Colors.red.shade600,
                          ),
                        ),

                        const SizedBox(height: 20),
                        Divider(color: Theme.of(context).dividerColor),
                        const SizedBox(height: 16),

                        // Rodapé Legal
                        Row(
                          children: [
                            Icon(Icons.gavel_rounded, color: Theme.of(context).colorScheme.primary, size: 14),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lei 15.138/2025 - Política Nacional de Assistência a DII',
                                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Mensagem Legal (Alerta) ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: alertBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: alertBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.priority_high_rounded, color: Color(0xFFF59E0B), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'DIREITO DE ACESSO URGENTE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: alertText,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'O portador deste cartão tem Doença Inflamatória Intestinal e necessita de ACESSO URGENTE E IMEDIATO a instalações sanitárias.',
                          style: TextStyle(
                            fontSize: 13,
                            color: alertText,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lei de Acesso - Diversos estados possuem legislação específica garantindo prioridade.',
                          style: TextStyle(
                            fontSize: 11,
                            color: alertText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Botão: Apresentar Laudo Médico ──
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: laudoUrl != null && laudoUrl.isNotEmpty
                          ? () => _openLaudo(laudoUrl)
                          : null,
                      icon: const Icon(Icons.description_rounded, size: 20),
                      label: const Text(
                        'Apresentar Laudo Médico',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  if (laudoUrl == null || laudoUrl.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                          SizedBox(width: 6),
                          Text(
                            'Laudo não encontrado. Complete o seu perfil.',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // ── Informação de Segurança ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.shield_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dados protegidos',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Suas informações médicas são criptografadas',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
