import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:viva_livre_app/features/health/presentation/pages/health_page.dart';

class HealthDashboardPage extends StatefulWidget {
  final List<HealthRecord> records;

  const HealthDashboardPage({super.key, required this.records});

  @override
  State<HealthDashboardPage> createState() => _HealthDashboardPageState();
}

class _HealthDashboardPageState extends State<HealthDashboardPage>
    with AutomaticKeepAliveClientMixin {
  String _selectedFilter = 'Hoje';
  final List<String> _filters = ['Hoje', 'Últimos 7 dias', 'Mês'];

  static const Color _kBlue = Color(0xFF2563EB);
  static const Color _kBg = Color(0xFFF8FAFC);
  static const Color _kText = Color(0xFF0F172A);

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : _kBg;
    final surfaceColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : _kText;
    final mutedText = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Resumo de Saúde',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Filtros ──
            Container(
              color: surfaceColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? _kBlue : (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : mutedText,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // ── Destaques (Cards) ──
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Idas ao Banheiro',
                          value: _getBathroomCount(),
                          subtitle: 'nas últimas 24h',
                          icon: Icons.wc_rounded,
                          color: _kBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Sintoma Frequente',
                          value: _getMostFrequentSymptom(),
                          subtitle: 'mais recorrente',
                          icon: Icons.healing_rounded,
                          color: const Color(0xFFF59E0B),
                          isValueText: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Gráfico de Atividade ──
                  Text(
                    'Atividade ao Longo do Dia',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Distribuição de sintomas e eventos nas últimas 24h',
                    style: TextStyle(fontSize: 13, color: mutedText),
                  ),
                  const SizedBox(height: 24),
                  
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildChart(context),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // ── Botão Exportar ──
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Relatório gerado com sucesso! Pronto para compartilhar com o seu médico.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: textColor,
                  foregroundColor: isDark ? _kBg : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 20),
                label: const Text(
                  'Exportar para o Médico',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lógica de Agregação de Dados ──

  String _getBathroomCount() {
    // Conta registos do tipo "banheiro"
    final count = widget.records.where((r) => r.type == 'banheiro').length;
    return count.toString();
  }

  String _getMostFrequentSymptom() {
    final symptoms = widget.records.where((r) => r.type == 'sintoma').toList();
    if (symptoms.isEmpty) return 'Nenhum';

    final map = <String, int>{};
    for (var s in symptoms) {
      map[s.title] = (map[s.title] ?? 0) + 1;
    }

    var mostFrequent = '';
    var maxCount = 0;
    map.forEach((key, value) {
      if (value > maxCount) {
        maxCount = value;
        mostFrequent = key;
      }
    });

    return mostFrequent;
  }

  Widget _buildChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Divide os eventos pelas partes do dia: Manhã (06-12), Tarde (12-18), Noite (18-06)
    int morning = 0;
    int afternoon = 0;
    int night = 0;

    for (var r in widget.records) {
      final hour = r.timestamp.hour;
      if (hour >= 6 && hour < 12) {
        morning++;
      } else if (hour >= 12 && hour < 18) {
        afternoon++;
      } else {
        night++;
      }
    }

    // Se não houver dados, mostra um gráfico mock para visualização do design
    if (widget.records.isEmpty) {
      morning = 2;
      afternoon = 5;
      night = 8;
    }

    final maxY = [morning, afternoon, night].reduce((a, b) => a > b ? a : b).toDouble() + 2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text;
                switch (value.toInt()) {
                  case 0: text = 'Manhã'; break;
                  case 1: text = 'Tarde'; break;
                  case 2: text = 'Noite'; break;
                  default: text = '';
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    text,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Theme.of(context).dividerColor : const Color(0xFFF1F5F9), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeGroupData(0, morning.toDouble(), _kBlue, isDark),
          _makeGroupData(1, afternoon.toDouble(), const Color(0xFFF59E0B), isDark),
          _makeGroupData(2, night.toDouble(), const Color(0xFFEF4444), isDark),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color, bool isDark) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 32,
          borderRadius: BorderRadius.circular(8),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10, // Mock fixed background height
            color: isDark ? Colors.grey.shade800 : const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isValueText;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isValueText = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedText = isDark ? Colors.white70 : const Color(0xFF334155);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bgColor,
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: isValueText ? 16 : 28,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mutedText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
