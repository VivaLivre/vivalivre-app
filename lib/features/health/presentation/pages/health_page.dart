import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:intl/intl.dart';
import 'package:viva_livre_app/features/health/presentation/pages/health_dashboard_page.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  Models
// ═════════════════════════════════════════════════════════════════════════════

class HealthRecord {
  final String id;
  final String title;
  final DateTime timestamp;
  final String type; // 'banheiro', 'sintoma'

  HealthRecord({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.type,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
//  Page
// ═════════════════════════════════════════════════════════════════════════════

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  // ── Constantes ──
  static const Color _kBlue = Color(0xFF2563EB);
  static const Color _kBg = Color(0xFFF8FAFC);
  static const Color _kText = Color(0xFF0F172A);
  static const Color _kSubText = Color(0xFF64748B);

  // ── Estado ──
  final List<HealthRecord> _timeline = [];
  
  final List<String> _baseSymptoms = [
    'Urgência evacuatória',
    'Tenesmo (vontade constante)',
    'Muco nas fezes',
    'Sangue nas fezes',
    'Dor em cólica',
    'Fadiga extrema',
    'Náusea',
    'Febre',
    'Dor articular',
  ];
  late List<String> _customSymptoms;

  @override
  void initState() {
    super.initState();
    _customSymptoms = List.from(_baseSymptoms);
  }

  // ── Lógica ──
  void _confirmDelete(int index) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Registo', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Tem a certeza que deseja excluir este registo?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: _kSubText)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _timeline.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addRecord(String title, String type) {
    Vibration.vibrate(duration: 30);
    setState(() {
      _timeline.insert(
        0,
        HealthRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          timestamp: DateTime.now(),
          type: type,
        ),
      );
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('$title registado agora.')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showAddSymptomModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SymptomSearchModal(
        availableSymptoms: _customSymptoms,
        onAdd: (symptom) {
          if (!_customSymptoms.contains(symptom)) {
            setState(() => _customSymptoms.add(symptom));
          }
          _addRecord(symptom, 'sintoma');
        },
      ),
    );
  }

  // ── UI Builders ──
  @override
  Widget build(BuildContext context) {
    final today = DateFormat("dd 'de' MMMM", 'pt_BR').format(DateTime.now());

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -- Header --
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
                          Navigator.pushNamed(context, '/health-dashboard', arguments: _timeline);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // -- Acesso Rapido: Banheiro --
                  GestureDetector(
                    onTap: () { HapticFeedback.vibrate(); HapticFeedback.heavyImpact(); _addRecord('Ida ao Banheiro', 'banheiro'); },
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

            // -- Timeline --
            Expanded(
              child: _timeline.isEmpty
                  ? const _EmptyTimeline()
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _timeline.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onLongPress: () => _confirmDelete(index),
                          child: _TimelineItem(
                            record: _timeline[index],
                            isLast: index == _timeline.length - 1,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      
      // -- FAB Adicionar Sintoma --ma ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSymptomModal,
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
            child: const Icon(Icons.sentiment_satisfied_alt_rounded, size: 64, color: Color(0xFF94A3B8)),
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
  final HealthRecord record;
  final bool isLast;

  const _TimelineItem({required this.record, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(record.timestamp);
    final isBathroom = record.type == 'banheiro';

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

          // Coluna da linha e ponto
          Column(
            children: [
              const SizedBox(height: 18),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isBathroom ? const Color(0xFF2563EB) : const Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (isBathroom ? const Color(0xFF2563EB) : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Coluna do conteúdo (Card)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
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
                      color: isBathroom ? const Color(0xFF2563EB) : const Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        record.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
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
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Modal de Pesquisa�de Sintomas
// ═════════════════════════════════════════════════════════════════════════════

class _SymptomSearchModal extends StatefulWidget {
  final List<String> availableSymptoms;
  final Function(String) onAdd;

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
                               !widget.availableSymptoms.any((s) => s.toLowerCase() == query.toLowerCase());

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Puxador ──
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
            'Adicionar Sintoma',
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
                      autofocus: true,
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
                      },
                      child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Lista de Resultados ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _filtered.length + (showCustomAdd ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _filtered.length) {
                  // Botão "Outros" Customizado
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: GestureDetector(
                      onTap: () {
                        widget.onAdd(query);
                        Navigator.pop(context);
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
                            const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2563EB)),
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
                  );
                }

                final symptom = _filtered[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.healing_rounded, size: 18, color: Color(0xFFF59E0B)),
                  ),
                  title: Text(
                    symptom,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.add_rounded, color: Color(0xFF94A3B8)),
                  onTap: () {
                    widget.onAdd(symptom);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



