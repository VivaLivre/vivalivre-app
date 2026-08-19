import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viva_livre_app/features/health/presentation/pages/health_page.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';
import '../utils/health_data_aggregator.dart';
import '../utils/pdf_generator_service.dart';

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

    final filteredRecords = HealthDataAggregator.filterRecords(widget.records, _selectedFilter);
    final bathroomCount = HealthDataAggregator.countBathroomTrips(filteredRecords);
    final frequentSymptomData = HealthDataAggregator.getMostFrequentSymptom(filteredRecords);
    
    final frequentSymptom = frequentSymptomData?.key ?? 'Nenhum';
    final frequentSeverity = frequentSymptomData?.value;
    final severityColor = HealthDataAggregator.getSeverityColor(frequentSeverity);

    final symptomDistribution = HealthDataAggregator.getSymptomDistribution(filteredRecords);

    // Ajusta os textos de contexto
    String subtitleText = '';
    switch (_selectedFilter) {
      case 'Hoje': subtitleText = 'nas últimas 24h'; break;
      case 'Últimos 7 dias': subtitleText = 'nos últimos 7 dias'; break;
      case 'Mês': subtitleText = 'neste mês'; break;
    }

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Idas ao Banheiro',
                          value: bathroomCount.toString(),
                          subtitle: subtitleText,
                          icon: Icons.wc_rounded,
                          color: _kBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Sintoma Frequente',
                          value: frequentSymptom,
                          subtitle: frequentSymptom == 'Nenhum' ? 'Sem dados' : subtitleText,
                          icon: Icons.healing_rounded,
                          color: frequentSymptom == 'Nenhum' ? const Color(0xFFF59E0B) : severityColor,
                          isValueText: true,
                          badgeText: frequentSymptom == 'Nenhum' ? null : frequentSeverity,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Gráfico de Pizza: Distribuição de Sintomas ──
                  if (symptomDistribution.isNotEmpty) ...[
                    Text(
                      'Distribuição de Sintomas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quais foram os sintomas mais recorrentes $subtitleText',
                      style: TextStyle(fontSize: 13, color: mutedText),
                    ),
                    const SizedBox(height: 24),
                    Container(
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
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: _buildPieChartSections(symptomDistribution, isDark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildPieChartLegend(symptomDistribution, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ── Gráfico de Atividade (Barras) ──
                  Text(
                    'Atividade por Período',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Distribuição de sintomas e eventos $subtitleText',
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
                    child: _buildBarChart(filteredRecords, context),
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
                  final authState = context.read<AuthBloc>().state;
                  String userName = 'Paciente VivaLivre';
                  String condition = 'Não especificada';
                  if (authState is AuthAuthenticated) {
                    userName = authState.user.name;
                    condition = authState.user.clinicalCondition ?? 'Não especificada';
                  }

                  PdfGeneratorService.generateAndPreviewPdf(
                    records: filteredRecords,
                    filter: _selectedFilter,
                    userName: userName,
                    clinicalCondition: condition,
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

  // ── Helpers de Gráficos ──

  List<Color> _getChartColors(bool isDark) {
    return [
      _kBlue,
      const Color(0xFF10B981), // Verde
      const Color(0xFFF59E0B), // Laranja
      const Color(0xFF8B5CF6), // Roxo
      const Color(0xFFEF4444), // Vermelho
      const Color(0xFF06B6D4), // Ciano
    ];
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, double> data, bool isDark) {
    final colors = _getChartColors(isDark);
    int i = 0;
    
    return data.entries.map((entry) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.value.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildPieChartLegend(Map<String, double> data, bool isDark) {
    final colors = _getChartColors(isDark);
    int i = 0;

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: data.entries.map((entry) {
        final color = colors[i % colors.length];
        i++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              entry.key,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : _kText,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBarChart(List<HealthRecord> records, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Lógica para 'Hoje' (Por Partes do Dia)
    if (_selectedFilter == 'Hoje') {
      int morning = 0;
      int afternoon = 0;
      int night = 0;

      for (var r in records) {
        final hour = r.timestamp.hour;
        if (hour >= 6 && hour < 12) {
          morning++;
        } else if (hour >= 12 && hour < 18) {
          afternoon++;
        } else {
          night++;
        }
      }

      // Mock caso vazio
      if (records.isEmpty) { morning = 2; afternoon = 5; night = 1; }

      final maxY = [morning, afternoon, night].reduce((a, b) => a > b ? a : b).toDouble() + 2;

      return _renderBarChart(
        maxY: maxY,
        isDark: isDark,
        labels: ['Manhã', 'Tarde', 'Noite'],
        values: [morning.toDouble(), afternoon.toDouble(), night.toDouble()],
      );
    }
    
    // Lógica para 'Últimos 7 dias' ou 'Mês'
    // Agrupamento por Dia
    final map = <int, int>{};
    for (var r in records) {
      final key = r.timestamp.day; // Simplificado: usa o dia
      map[key] = (map[key] ?? 0) + 1;
    }

    if (map.isEmpty) {
      // Mock vazio para ver a UI
      return _renderBarChart(
        maxY: 5,
        isDark: isDark,
        labels: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex'],
        values: [1, 2, 0, 3, 1],
      );
    }

    // Ordenar os dias para exibir
    final sortedKeys = map.keys.toList()..sort();
    // Limitar a exibir os últimos 5 a 7 itens no gráfico para não apertar
    final recentKeys = sortedKeys.length > 7 ? sortedKeys.sublist(sortedKeys.length - 7) : sortedKeys;

    final labels = recentKeys.map((day) => 'Dia $day').toList();
    final values = recentKeys.map((day) => map[day]!.toDouble()).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b) + 2;

    return _renderBarChart(
      maxY: maxY,
      isDark: isDark,
      labels: labels,
      values: values,
    );
  }

  Widget _renderBarChart({required double maxY, required bool isDark, required List<String> labels, required List<double> values}) {
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
                final int index = value.toInt();
                if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[index],
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
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
          getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Theme.of(context).dividerColor : const Color(0xFFF1F5F9), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(values.length, (index) {
          return _makeGroupData(index, values[index], _kBlue, isDark, maxY);
        }),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color, bool isDark, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 24, // um pouco mais fino para suportar mais dias
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY, // Utiliza o limite máximo verdadeiro para o fundo
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
  final String? badgeText;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isValueText = false,
    this.badgeText,
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
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
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
          const SizedBox(height: 6),
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
