import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/presentation/health_bloc.dart';
import '../widgets/empty_timeline.dart';
import '../widgets/timeline_item.dart';
import '../widgets/symptom_search_modal.dart';
import '../widgets/bathroom_extras_modal.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  HealthRecord — alias de compatibilidade para o HealthDashboardPage
//  O dashboard ainda lê HealthRecord; mapeamos HealthEntry → HealthRecord aqui.
// ═════════════════════════════════════════════════════════════════════════════

class HealthRecord {
  final String id;
  final String title;
  final DateTime timestamp;
  final String type; // 'banheiro' | 'sintoma'

  HealthRecord({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.type,
  });

  /// Converte uma [HealthEntry] do domínio para o formato do Dashboard.
  factory HealthRecord.fromEntry(HealthEntry entry) {
    return HealthRecord(
      id: entry.id,
      title: entry.symptoms.isNotEmpty
          ? entry.symptoms.join(', ')
          : 'Registo sem sintoma',
      timestamp: entry.timestamp,
      type: entry.type,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  HealthPage
// ═════════════════════════════════════════════════════════════════════════════

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage>
    with AutomaticKeepAliveClientMixin {
  // ── Constantes de design — INALTERADAS ──
  // ── Lista de sintomas disponíveis para o modal de pesquisa ──
  final List<String> _baseSymptoms = [
    'Dor Abdominal',
    'Diarreia',
    'Sangue nas Fezes',
    'Fadiga Extrema',
    'Febre',
    'Náusea/Vómito',
    'Gases/Inchaço',
    'Perda de Apetite',
    'Dores Articulares',
    'Cólica Intestinal',
    'Urgência Evacuatória',
    'Incontinência Fecal',
    'Muco nas Fezes',
    'Constipação/Prisão de Ventre',
    'Azia',
    'Refluxo',
    'Dor de Cabeça',
    'Enxaqueca',
    'Tontura',
    'Calafrios',
    'Suores Noturnos',
    'Aftas',
    'Feridas na Boca',
    'Lesões na Pele',
    'Eritema Nodoso',
    'Olhos Vermelhos/Irritados',
    'Visão Embaçada',
    'Perda de Peso',
    'Anemia',
    'Fraqueza',
    'Desidratação',
    'Boca Seca',
    'Palpitações',
    'Ansiedade',
    'Insónia',
    'Alterações de Humor',
    'Dor Lombar',
    'Cãibras',
    'Espasmos Musculares',
    'Parestesia/Formigueiro',
    'Dor de Garganta',
    'Tosse',
    'Falta de Ar',
    'Olho Seco',
    'Coceira/Prurido',
    'Dificuldade de Concentração',
  ];
  late List<String> _customSymptoms;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _customSymptoms = List.from(_baseSymptoms);

    // No novo backend, o userId é inferido do Token JWT.
    context.read<HealthBloc>().add(const WatchHealthEntries(''));
  }

  // ── Lógica ──

  /// Abre o modal "E mais alguma coisa?" antes de gravar a ida ao banheiro.
  /// Sintomas adicionais são incluídos no MESMO documento Firestore —
  /// um único .add() mantém o banco de dados leve.
  Future<void> _showBathroomModal() async {
    Vibration.vibrate(duration: 80);

    final List<String>? extraSymptoms =
        await showModalBottomSheet<List<String>>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const BathroomExtrasModal(),
        );

    if (!mounted) return;

    final symptoms = ['Ida ao Banheiro', ...?extraSymptoms];

    final severity = HealthEntry.calculateSeverity(symptoms);

    final entry = HealthEntry(
      id: '',
      userId: '',
      symptoms: symptoms,
      severity: severity,
      notes: '',
      timestamp: DateTime.now(),
      type: 'banheiro',
    );

    context.read<HealthBloc>().add(AddHealthEntry(entry));
    Vibration.vibrate(duration: 150, amplitude: 255);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).cardColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  symptoms.length > 1
                      ? 'Registado com ${symptoms.length - 1} sintoma(s) adicional(is).'
                      : 'Ida ao Banheiro registada.',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showAddSymptomModal(List<HealthEntry> currentEntries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SymptomSearchModal(
        availableSymptoms: _customSymptoms,
        onAdd: (List<String> symptoms) {
          for (var symptom in symptoms) {
            if (!_customSymptoms.contains(symptom)) {
              setState(() => _customSymptoms.add(symptom));
            }
          }

          Vibration.vibrate(duration: 150, amplitude: 255);

          final severity = HealthEntry.calculateSeverity(symptoms);

          final entry = HealthEntry(
            id: '',
            userId: '',
            symptoms: symptoms,
            severity: severity,
            notes: '',
            timestamp: DateTime.now(),
            type: 'sintoma',
          );

          context.read<HealthBloc>().add(AddHealthEntry(entry));

          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Theme.of(context).cardColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${symptoms.join(', ')} registado.')),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
        },
      ),
    );
  }

  // ── UI ──
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final today = DateFormat("dd 'de' MMMM", 'pt_BR').format(DateTime.now());

    return BlocBuilder<HealthBloc, HealthState>(
      builder: (context, state) {
        final entries = state is HealthEntriesLoaded
            ? state.entries
            : <HealthEntry>[];
        final records = entries.map(HealthRecord.fromEntry).toList();
        final isLoading = state is HealthLoading;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Diário Clínico',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                today,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.bar_chart_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            tooltip: 'Ver Resumo',
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/health-dashboard',
                                arguments: records,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Botão Rápido: Banheiro ──
                      GestureDetector(
                        onTap: _showBathroomModal,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF3B82F6), Theme.of(context).colorScheme.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wc_rounded,
                                color: Theme.of(context).cardColor,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Registrar Ida ao Banheiro',
                                style: TextStyle(
                                  color: Theme.of(context).cardColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Timeline ──
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                        )
                      : entries.isEmpty
                      ? const EmptyTimeline()
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            return TimelineItem(
                              entry: entries[index],
                              isLast: index == entries.length - 1,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // ── FAB Sintoma ──
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSymptomModal(entries),
            backgroundColor: Theme.of(context).cardColor,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            icon: Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.primary),
            label: const Text(
              'Sintoma',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Componentes da Timeline
// ═════════════════════════════════════════════════════════════════════════════
