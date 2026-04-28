import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CartaoDIIPage extends StatelessWidget {
  const CartaoDIIPage({super.key});

  // ── Paleta de Cores (Design System Médico) ──
  static const Color _kBg = Color(0xFFF8FAFC);
  static const Color _kBlue = Color(0xFF2563EB);
  static const Color _kText = Color(0xFF1E293B);
  static const Color _kSubText = Color(0xFF64748B);
  static const Color _kCardBorder = Color(0xFFE2E8F0);
  static const Color _kAlertBg = Color(0xFFFEF3C7);
  static const Color _kAlertText = Color(0xFF92400E);

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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _kBg,
        body: const Center(
          child: Text('Usuário não autenticado', style: TextStyle(color: _kSubText)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, snapshot) {
            // ── Estado de Carregamento ──
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _kBlue),
              );
            }

            // ── Estado de Erro ──
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar dados',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kText),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: _kSubText),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ── Documento não existe ou sem dados ──
            if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, size: 48, color: Color(0xFFF59E0B)),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Dados não encontrados',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kText),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Complete o seu perfil para visualizar o cartão DII.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: _kSubText),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ── Extração de Dados do Firestore ──
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final String? cid = data != null ? data['cid'] as String? : null;
            final String? laudoUrl = data != null ? data['laudoUrl'] as String? : null;
            final String userName = user.displayName ?? 'Usuário';

            // ── UI Principal ──
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──
                  const Row(
                    children: [
                      Icon(Icons.badge_rounded, color: _kBlue, size: 28),
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
                                color: _kSubText,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Cartão de Identificação DII',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _kText,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBlue, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _kBlue.withValues(alpha: 0.15),
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
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.medical_information_rounded, color: _kBlue, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'CARTÃO DE IDENTIFICAÇÃO DII',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _kBlue,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: _kCardBorder),
                        const SizedBox(height: 20),

                        // Nome do Titular
                        const Text(
                          'TITULAR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _kSubText,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _kText,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // CID
                        const Text(
                          'CID',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _kSubText,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cid ?? 'Não informado',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cid != null ? _kText : Colors.red.shade600,
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: _kCardBorder),
                        const SizedBox(height: 16),

                        // Rodapé Legal
                        const Row(
                          children: [
                            Icon(Icons.gavel_rounded, color: _kBlue, size: 14),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lei 15.138/2025 - Política Nacional de Assistência a DII',
                                style: TextStyle(fontSize: 10, color: _kSubText),
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
                      color: _kAlertBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.priority_high_rounded, color: Color(0xFFF59E0B), size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'DIREITO DE ACESSO URGENTE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _kAlertText,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'O portador deste cartão tem Doença Inflamatória Intestinal e necessita de ACESSO URGENTE E IMEDIATO a instalações sanitárias.',
                          style: TextStyle(
                            fontSize: 13,
                            color: _kAlertText,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Lei de Acesso - Diversos estados possuem legislação específica garantindo prioridade.',
                          style: TextStyle(
                            fontSize: 11,
                            color: _kAlertText,
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
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  if (laudoUrl == null || laudoUrl.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: _kSubText),
                          const SizedBox(width: 6),
                          Text(
                            'Laudo não encontrado. Complete o seu perfil.',
                            style: const TextStyle(fontSize: 12, color: _kSubText),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // ── Informação de Segurança ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _kCardBorder),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shield_rounded, color: _kBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dados protegidos',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _kText),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Suas informações médicas são criptografadas',
                                style: TextStyle(fontSize: 12, color: _kSubText),
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
            );
          },
        ),
      ),
    );
  }
}
