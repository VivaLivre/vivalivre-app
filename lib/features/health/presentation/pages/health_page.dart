import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/presentation/health_bloc.dart';

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

class _HealthPageState extends State<HealthPage> {
  // ── Constantes de design — INALTERADAS ──
  static const Color _kBlue = Color(0xFF2563EB);
  static const Color _kBg = Color(0xFFF8FAFC);
  static const Color _kText = Color(0xFF0F172A);
  static const Color _kSubText = Color(0xFF64748B);

  // ── Lista de sintomas disponíveis para o modal de pesquisa ──
  final List<String> _baseSymptoms = [
    'Dor Abdominal', 'Diarreia', 'Sangue nas Fezes', 'Fadiga Extrema',
    'Febre', 'Náusea/Vómito', 'Gases/Inchaço', 'Perda de Apetite',
    'Dores Articulares', 'Cólica Intestinal', 'Urgência Evacuatória',
    'Incontinência Fecal', 'Muco nas Fezes', 'Constipação/Prisão de Ventre',
    'Azia', 'Refluxo', 'Dor de Cabeça', 'Enxaqueca', 'Tontura', 'Calafrios',
    'Suores Noturnos', 'Aftas', 'Feridas na Boca', 'Lesões na Pele',
    'Eritema Nodoso', 'Olhos Vermelhos/Irritados', 'Visão Embaçada',
    'Perda de Peso', 'Anemia', 'Fraqueza', 'Desidratação', 'Boca Seca',
    'Palpitações', 'Ansiedade', 'Insónia', 'Alterações de Humor',
  ];
  late List<String> _customSymptoms;

  @override
  void initState() {
    super.initState();
    _customSymptoms = List.from(_baseSymptoms);

    // Inicia a escuta do Stream do Firestore para o utilizador logado.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      context.read<HealthBloc>().add(WatchHealthEntries(uid));
    }
  }

  // ── Lógica ──

  /// Abre o modal "E mais alguma coisa?" antes de gravar a ida ao banheiro.
  /// Sintomas adicionais são incluídos no MESMO documento Firestore —
  /// um único .add() mantém o banco de dados leve.
  Future<void> _showBathroomModal() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    Vibration.vibrate(duration: 80);

    final List<String>? extraSymptoms = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _BathroomExtrasModal(),
    );

    // null → fechou sem responder → registamos ida simples
    // [] → clicou "Não, só isso" → ida simples
    // [sintomas...] → ida enriquecida com sintomas
    if (!mounted) return;

    final symptoms = ['Ida ao Banheiro', ...?extraSymptoms];

    // Calcula gravidade automaticamente com base nos sintomas extras
    // Regra: 1 sintoma grave = Grave imediatamente
    const severeSymptoms = [
      'Sangue nas Fezes', 'Fadiga Extrema', 'Febre', 'Incontinência Fecal',
      'Desidratação', 'Perda de Peso', 'Anemia', 'Desmaios', 'Convulsões',
      'Dor Intensa no Peito', 'Dificuldade para Respirar', 'Febre Alta',
    ];
    final hasSevere = symptoms.any((s) => severeSymptoms.contains(s));
    final severity = hasSevere
        ? 'Grave'
        : symptoms.length >= 4
            ? 'Moderada'
            : 'Leve';

    final entry = HealthEntry(
      id: '',
      userId: uid,
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
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      builder: (context) => _SymptomSearchModal(
        availableSymptoms: _customSymptoms,
        onAdd: (List<String> symptoms) {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
          if (uid.isEmpty) return;

          for (var symptom in symptoms) {
            if (!_customSymptoms.contains(symptom)) {
              setState(() => _customSymptoms.add(symptom));
            }
          }

          Vibration.vibrate(duration: 150, amplitude: 255);

          final entry = HealthEntry(
            id: '',
            userId: uid,
            symptoms: symptoms,
            severity: 'Leve',
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
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${symptoms.join(', ')} registado.')),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final today = DateFormat("dd 'de' MMMM", 'pt_BR').format(DateTime.now());

    return BlocBuilder<HealthBloc, HealthState>(
      builder: (context, state) {
        final entries = state is HealthEntriesLoaded ? state.entries : <HealthEntry>[];
        final records = entries.map(HealthRecord.fromEntry).toList();
        final isLoading = state is HealthLoading;

        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                              const Text(
                                'Diário Clínico',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: _kText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                today,
                                style: const TextStyle(fontSize: 14, color: _kSubText),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.bar_chart_rounded, color: _kBlue),
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
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), _kBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _kBlue.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wc_rounded, color: Colors.white, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Registrar Ida ao Banheiro',
                                style: TextStyle(
                                  color: Colors.white,
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
                      ? const Center(
                          child: CircularProgressIndicator(color: _kBlue),
                        )
                      : entries.isEmpty
                          ? const _EmptyTimeline()
                          : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: entries.length,
                              itemBuilder: (context, index) {
                                return _TimelineItem(
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
            backgroundColor: Colors.white,
            foregroundColor: _kText,
            icon: const Icon(Icons.add_rounded, color: _kBlue),
            label: const Text('Sintoma', style: TextStyle(fontWeight: FontWeight.w700)),
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

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.sentiment_satisfied_alt_rounded,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tudo tranquilo por aqui.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nenhum evento registado ainda hoje.\nContinue a cuidar da sua saúde!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final HealthEntry entry;
  final bool isLast;

  const _TimelineItem({required this.entry, required this.isLast});

  static Color _severityColor(String severity) {
    return switch (severity) {
      'Grave'    => const Color(0xFFEF4444),
      'Moderada' => const Color(0xFFF59E0B),
      _          => const Color(0xFF10B981),
    };
  }

  void _showMenu(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        bottom: true,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // ── Ver Detalhes ──
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
              ),
              title: const Text('Ver Detalhes',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Horário, sintomas e notas completas'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => _EntryDetailDialog(entry: entry),
                );
              },
            ),
            const Divider(height: 1),
            // ── Eliminar ──
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEF2F2),
                child: Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              ),
              title: const Text('Eliminar Registo',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
              subtitle: const Text('Esta acção não pode ser desfeita'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text('Eliminar registo?',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    content: const Text(
                      'Este registo será removido permanentemente do seu histórico clínico.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar',
                            style: TextStyle(color: Color(0xFF64748B))),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<HealthBloc>().add(
                            DeleteHealthEntry(docId: entry.id, userId: uid),
                          );
                        },
                        child: const Text('Eliminar',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),   // fecha Container
      ),   // fecha SafeArea
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(entry.timestamp);
    final isBathroom = entry.type == 'banheiro';
    final dotColor = _severityColor(entry.severity);
    final title = entry.symptoms.isNotEmpty
        ? entry.symptoms.join(', ')
        : 'Registo';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coluna da hora
          SizedBox(
            width: 50,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Ponto + linha — cor pela severidade
          Column(
            children: [
              const SizedBox(height: 18),
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: dotColor.withValues(alpha: 0.35), blurRadius: 5),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: const Color(0xFFE2E8F0))),
            ],
          ),
          const SizedBox(width: 16),

          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dotColor.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isBathroom ? Icons.wc_rounded : Icons.healing_rounded,
                      color: dotColor, size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.severity != 'Leve')
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: dotColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          entry.severity,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: dotColor,
                          ),
                        ),
                      ),
                    // ── 3 pontos ──
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Color(0xFF94A3B8), size: 20),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      tooltip: 'Opções',
                      onPressed: () => _showMenu(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  _EntryDetailDialog — Detalhes completos de um registo clínico (Dialog)
// ═════════════════════════════════════════════════════════════════════════════

class _EntryDetailDialog extends StatelessWidget {
  final HealthEntry entry;
  const _EntryDetailDialog({required this.entry});

  static Color _severityColor(String severity) {
    return switch (severity) {
      'Grave'    => const Color(0xFFEF4444),
      'Moderada' => const Color(0xFFF59E0B),
      _          => const Color(0xFF10B981),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dotColor   = _severityColor(entry.severity);
    final isBathroom = entry.type == 'banheiro';
    final dateStr    = DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(entry.timestamp);
    final timeStr    = DateFormat('HH:mm:ss').format(entry.timestamp);
    final uid        = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFFF8FAFC),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header colorido
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
            decoration: BoxDecoration(
              color: dotColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: dotColor.withValues(alpha: 0.15))),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: dotColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(isBathroom ? Icons.wc_rounded : Icons.healing_rounded, color: dotColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isBathroom ? 'Ida ao Banheiro' : 'Registo de Sintomas',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(dateStr + ' às ' + timeStr,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: dotColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: dotColor.withValues(alpha: 0.4)),
                ),
                child: Text(entry.severity,
                  style: TextStyle(color: dotColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const SizedBox(width: 4),
            ]),
          ),
          // Corpo scrollável
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _DetailSection(
                  icon: Icons.list_alt_rounded,
                  label: 'Sintomas (' + entry.symptoms.length.toString() + ')',
                  child: Wrap(spacing: 6, runSpacing: 6,
                    children: entry.symptoms.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (entry.notes.isNotEmpty) ...[
                  _DetailSection(
                    icon: Icons.notes_rounded,
                    label: 'Observações',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(entry.notes,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _DetailSection(
                  icon: isBathroom ? Icons.wc_rounded : Icons.healing_rounded,
                  label: 'Tipo de registo',
                  child: Text(isBathroom ? 'Ida ao Banheiro' : 'Registo de Sintomas',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
          // Rodapé com ações
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Fechar', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Eliminar registo?', style: TextStyle(fontWeight: FontWeight.w700)),
                      content: const Text('Este registo será removido permanentemente do seu histórico clínico.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.read<HealthBloc>().add(
                              DeleteHealthEntry(docId: entry.id, userId: uid),
                            );
                          },
                          child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                },
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _DetailSection({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
//  Modal de Pesquisa de Sintomas — ESTÉTICA ORIGINAL PRESERVADA
// ═════════════════════════════════════════════════════════════════════════════

class _SymptomSearchModal extends StatefulWidget {
  final List<String> availableSymptoms;
  final Function(List<String>) onAdd;

  const _SymptomSearchModal({
    required this.availableSymptoms,
    required this.onAdd,
  });

  @override
  State<_SymptomSearchModal> createState() => _SymptomSearchModalState();
}

class _SymptomSearchModalState extends State<_SymptomSearchModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _filtered = [];
  List<String> selectedSymptoms = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.availableSymptoms;
  }

  void _filter(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filtered = widget.availableSymptoms;
      } else {
        _filtered = widget.availableSymptoms
            .where((s) => s.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim();
    final bool showCustomAdd = query.isNotEmpty &&
        !widget.availableSymptoms
            .any((s) => s.toLowerCase() == query.toLowerCase());

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Adicionar Sintomas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _filter,
                      decoration: const InputDecoration(
                        hintText: 'Pesquisar sintoma...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  if (query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        _filter('');
                        FocusScope.of(context).unfocus();
                      },
                      child: const Icon(Icons.close_rounded,
                          color: Color(0xFF94A3B8), size: 20),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Lista de Chips ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _filtered.map((symptom) {
                      return FilterChip(
                        label: Text(symptom),
                        selected: selectedSymptoms.contains(symptom),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              selectedSymptoms.add(symptom);
                            } else {
                              selectedSymptoms.remove(symptom);
                            }
                          });
                        },
                        // ── CORES ORIGINAIS PRESERVADAS ──
                        selectedColor:
                            const Color(0xFF2563EB).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF2563EB),
                      );
                    }).toList(),
                  ),
                  if (showCustomAdd)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 24),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSymptoms.add(query);
                            _searchCtrl.clear();
                            _filter('');
                            FocusScope.of(context).unfocus();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline_rounded,
                                  color: Color(0xFF2563EB)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Adicionar "$query" como novo',
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Botão Salvar ──
          SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: selectedSymptoms.isEmpty
                      ? null
                      : () {
                          Vibration.vibrate(duration: 150, amplitude: 255);
                          widget.onAdd(selectedSymptoms);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  } // fecha build()
} // fecha _SymptomSearchModalState

// ═════════════════════════════════════════════════════════════════════════════
//  _BathroomExtrasModal — "E mais alguma coisa?"
//  Modal compacto que permite registar sintomas comuns junto com a ida
//  ao banheiro, tudo num único documento Firestore.
// ═════════════════════════════════════════════════════════════════════════════

class _BathroomExtrasModal extends StatefulWidget {
  const _BathroomExtrasModal();

  @override
  State<_BathroomExtrasModal> createState() => _BathroomExtrasModalState();
}

class _BathroomExtrasModalState extends State<_BathroomExtrasModal> {
  // Sintomas mais comuns associados a uma ida ao banheiro na DII
  static const List<String> _quickSymptoms = [
    'Dor Abdominal',
    'Diarreia',
    'Sangue nas Fezes',
    'Urgência Evacuatória',
    'Cólica Intestinal',
    'Incontinência Fecal',
    'Muco nas Fezes',
    'Gases/Inchaço',
    'Náusea/Vómito',
    'Fadiga Extrema',
  ];

  final List<String> _selected = [];

  static const Color _kBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        // viewInsets.bottom = teclado; viewPadding.bottom = barra de navegação
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Alça visual ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Título ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wc_rounded, color: _kBlue, size: 22),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'E mais alguma coisa?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Opcional — tudo fica num registo só.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Chips de sintomas rápidos ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSymptoms.map((symptom) {
              final isSelected = _selected.contains(symptom);
              return FilterChip(
                label: Text(symptom),
                selected: isSelected,
                onSelected: (val) {
                  Vibration.vibrate(duration: 30);
                  setState(() {
                    if (val) {
                      _selected.add(symptom);
                    } else {
                      _selected.remove(symptom);
                    }
                  });
                },
                selectedColor: _kBlue.withValues(alpha: 0.15),
                checkmarkColor: _kBlue,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? _kBlue : const Color(0xFFE2E8F0),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? _kBlue : const Color(0xFF0F172A),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Botões ──
          Row(
            children: [
              // Botão: Não, só isso
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, <String>[]),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Não, só isso',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botão: Adicionar
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Vibration.vibrate(duration: 60);
                    Navigator.pop(context, _selected);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selected.isEmpty ? 'Só a ida' : 'Adicionar (${_selected.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
