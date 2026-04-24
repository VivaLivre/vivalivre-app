import 'package:flutter/material.dart';
import 'dart:math';

class CartaoDIIPage extends StatefulWidget {
  const CartaoDIIPage({super.key});

  @override
  State<CartaoDIIPage> createState() => _CartaoDIIPageState();
}

class _CartaoDIIPageState extends State<CartaoDIIPage> {
  bool _copied = false;

  void _handleShare() {
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'VIVALIVRE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cartão DII',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.6)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF059669)),
                        SizedBox(width: 4),
                        Text(
                          'Verificado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Content ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  // Digital Card
                  const _DigitalIDCard(),
                  const SizedBox(height: 16),

                  // Subtitle
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Apresente este cartão digital para garantir acesso prioritário a sanitários em qualquer estabelecimento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _handleShare,
                          icon: Icon(_copied ? Icons.check_rounded : Icons.share_rounded, size: 18),
                          label: Text(_copied ? 'Link copiado!' : 'Compartilhar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _copied ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Baixar PDF'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF374151),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: const Color(0xFFF9FAFB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Security Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cartão seguro e verificado',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1F2937)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'QR Code com autenticação em tempo real',
                                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Legal Accordion
                  const _LegalInfo(),
                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    children: [
                      _StatCard(value: '142', label: 'Dias ativo', valueColor: const Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      _StatCard(value: '28', label: 'Usos regs.', valueColor: const Color(0xFF059669)),
                      const SizedBox(width: 12),
                      _StatCard(value: '4.9', label: 'Avaliação', valueColor: const Color(0xFFD97706)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Center(
                    child: Text(
                      'VivaLivre v2.4.1 · Cartão DII Digital',
                      style: TextStyle(fontSize: 11, color: Color(0xFFD1D5DB)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatCard({required this.value, required this.label, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}

// ── Accordion ─────────────────────────────────────────────────────────────────

class _LegalInfo extends StatefulWidget {
  const _LegalInfo();

  @override
  State<_LegalInfo> createState() => _LegalInfoState();
}

class _LegalInfoState extends State<_LegalInfo> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFFDBEAFE)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seus direitos como portador de DII', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1F2937))),
                    Text('Lei nº 13.146/2015 e Lei nº 14.538/2023', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  'Acesso prioritário a sanitários em locais públicos e privados',
                  'O estabelecimento não pode negar o acesso ao banheiro',
                  'Em caso de recusa, registre Boletim de Ocorrência',
                  'Apresente este cartão e mencione a Lei Federal nº 13.146',
                ].map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4))),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── The Digital Card UI ───────────────────────────────────────────────────────

class _DigitalIDCard extends StatefulWidget {
  const _DigitalIDCard();

  @override
  State<_DigitalIDCard> createState() => _DigitalIDCardState();
}

class _DigitalIDCardState extends State<_DigitalIDCard> with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 230),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x730F3482), blurRadius: 64, offset: Offset(0, 24)),
          BoxShadow(color: Color(0x400F3482), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Background Gradients ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B2F7C), Color(0xFF1648B8), Color(0xFF0D1F5C)],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          
          // Iridescent holographic shimmer
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  const Color(0x2E64C8FF),
                  const Color(0x23B482FF),
                  const Color(0x1E50E6B4),
                  Colors.transparent,
                ],
                stops: const [0.2, 0.38, 0.52, 0.64, 0.78],
              ),
            ),
          ),

          // Animated Light Sweep
          AnimatedBuilder(
            animation: _sweepController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(MediaQuery.of(context).size.width * (_sweepController.value * 2.6 - 1.3), 0),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.transparent, Color(0x1FFFFFFF), Colors.transparent],
                      stops: [0.3, 0.48, 0.66],
                    ),
                  ),
                ),
              );
            },
          ),

          // Micro-dot pattern (simulated using custom painter)
          Positioned.fill(child: CustomPaint(painter: _MicroDotPainter())),

          // Corner Glows
          Positioned(
            top: -32, right: -32,
            child: Container(
              width: 144, height: 144,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0x3364B4FF), Colors.transparent], stops: [0.0, 0.7]),
              ),
            ),
          ),
          Positioned(
            bottom: -40, left: -32,
            child: Container(
              width: 128, height: 128,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0x1E8C64FF), Colors.transparent], stops: [0.0, 0.7]),
              ),
            ),
          ),

          // ── Card Content ──
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomPaint(painter: _SealPainter(), size: const Size(48, 48)),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('REPÚBLICA FEDERATIVA DO BRASIL', style: TextStyle(color: Color(0x8CFFFFFF), fontSize: 8.5, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                              Text('CARTÃO DE PRIORIDADE DII', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                              Text('Doença Inflamatória Intestinal', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 9.5)),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.location_on_rounded, color: Colors.white, size: 10),
                                SizedBox(width: 4),
                                Text('VivaLivre', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              const Text('VÁLIDO', style: TextStyle(color: Color(0x8CFFFFFF), fontSize: 8.5, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  // Divider
                  Container(
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.transparent, Color(0x40FFFFFF), Colors.transparent]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Main Body
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo placeholder
                        Container(
                          width: 68, height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white54, size: 48),
                        ),
                        const SizedBox(width: 16),

                        // Info fields
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _InfoField('TITULAR', 'Marcos O. Silva', isLarge: true),
                              Row(
                                children: [
                                  Expanded(child: _InfoField('N° REGISTRO', 'VL-2025-00842', isMono: true)),
                                  Expanded(child: _InfoField('CID', 'K50/K51', isMono: true)),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(child: _InfoField('DATA EMISSÃO', '04/01/2025')),
                                  Expanded(child: _InfoField('VALIDADE', '31/12/2026')),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // QR Code
                        Column(
                          children: [
                            Container(
                              width: 80, height: 80,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.qr_code_2_rounded, size: 72, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 6),
                            const Text('Escaneie\npara validar', textAlign: TextAlign.center, style: TextStyle(color: Color(0x73FFFFFF), fontSize: 8, height: 1.2)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Legal footer
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0x2EFFFFFF))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.gavel_rounded, color: Color(0xD9FDE047), size: 12),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'Lei Federal nº 13.146/2015 ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xE6FEF08A))),
                                TextSpan(text: '· Lei Federal — Acesso prioritário a sanitários públicos e privados.'),
                              ],
                            ),
                            style: TextStyle(color: Color(0xA6FFFFFF), fontSize: 8.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Brazilian flag accent stripe
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: 6,
            child: Row(
              children: [
                Expanded(child: Container(color: const Color(0x8C22C55E))),
                Expanded(child: Container(color: const Color(0x99FACC15))),
                Expanded(child: Container(color: const Color(0x8093C5FD))),
                Expanded(child: Container(color: const Color(0x4DFFFFFF))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final bool isLarge;
  final bool isMono;

  const _InfoField(this.label, this.value, {this.isLarge = false, this.isMono = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0x73FFFFFF), fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
        Text(value, style: TextStyle(color: Colors.white, fontSize: isLarge ? 14 : 11, fontWeight: FontWeight.bold, fontFamily: isMono ? 'monospace' : null)),
      ],
    );
  }
}

// ── Custom Painters for Card Effects ──────────────────────────────────────────

class _MicroDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    
    for (double x = 0; x < size.width; x += 10) {
      for (double y = 0; y < size.height; y += 10) {
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SealPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    final fillPaint = Paint()..color = Colors.white.withValues(alpha: 0.07)..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = Colors.white.withValues(alpha: 0.55)..style = PaintingStyle.stroke..strokeWidth = 1.2;
    canvas.drawCircle(center, 24, fillPaint);
    canvas.drawCircle(center, 24, strokePaint);
    
    strokePaint..color = Colors.white.withValues(alpha: 0.35)..strokeWidth = 0.7;
    canvas.drawCircle(center, 19, strokePaint);
    
    fillPaint.color = Colors.white.withValues(alpha: 0.04);
    strokePaint..color = Colors.white.withValues(alpha: 0.22)..strokeWidth = 0.5;
    canvas.drawCircle(center, 14, fillPaint);
    canvas.drawCircle(center, 14, strokePaint);

    strokePaint.color = Colors.white.withValues(alpha: 0.38);
    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5 * pi) / 180;
      final start = Offset(center.dx + 15 * cos(angle), center.dy + 15 * sin(angle));
      final end = Offset(center.dx + 21 * cos(angle), center.dy + 21 * sin(angle));
      canvas.drawLine(start, end, strokePaint);
    }

    // Cross
    final crossPaint = Paint()..color = Colors.white.withValues(alpha: 0.75)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: 4, height: 12), const Radius.circular(1.5)), crossPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: 12, height: 4), const Radius.circular(1.5)), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
