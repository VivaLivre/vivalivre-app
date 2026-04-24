import 'package:flutter/material.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  int _currentDayIndex = 3; // Quarta-feira mock
  String? _selectedMood;
  final Set<int> _selectedSymptoms = {};
  final Map<String, bool> _medicationStatus = {};

  final List<String> _daysOfWeek = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  final List<Map<String, dynamic>> _symptoms = [
    {'id': 1, 'label': 'Dor Abdominal'},
    {'id': 2, 'label': 'Náusea'},
    {'id': 3, 'label': 'Fadiga'},
  ];

  final List<Map<String, dynamic>> _medications = [
    {
      'id': 1,
      'name': 'Mesalazina',
      'dosage': '800mg',
      'times': ['08:00', '20:00'],
      'taken': [true, false],
      'color': const Color(0xFF2563EB),
    },
    {
      'id': 2,
      'name': 'Infliximabe',
      'dosage': '5mg/kg',
      'times': ['Quinzenal'],
      'taken': [true],
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 3,
      'name': 'Prednisona',
      'dosage': '20mg',
      'times': ['09:00'],
      'taken': [false],
      'color': const Color(0xFFEC4899),
    },
  ];

  final List<Map<String, dynamic>> _moodOptions = [
    {
      'id': 'great',
      'label': 'Ótimo',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': const Color(0xFF10B981),
      'bgColor': const Color(0xFFD1FAE5),
    },
    {
      'id': 'okay',
      'label': 'Ok',
      'icon': Icons.sentiment_satisfied_rounded,
      'color': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFFFEF3C7),
    },
    {
      'id': 'bad',
      'label': 'Ruim',
      'icon': Icons.sentiment_dissatisfied_rounded,
      'color': const Color(0xFFF97316),
      'bgColor': const Color(0xFFFFEDD5),
    },
    {
      'id': 'pain',
      'label': 'Dor',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFFE11D48),
      'bgColor': const Color(0xFFFFE4E6),
    },
  ];

  void _toggleSymptom(int id) {
    setState(() {
      if (_selectedSymptoms.contains(id)) {
        _selectedSymptoms.remove(id);
      } else {
        _selectedSymptoms.add(id);
      }
    });
  }

  void _toggleMedication(int medId, int timeIndex) {
    setState(() {
      final key = '$medId-$timeIndex';
      _medicationStatus[key] = !(_medicationStatus[key] ?? false);
    });
  }

  bool _isMedicationTaken(Map<String, dynamic> med, int timeIndex) {
    final key = '${med['id']}-$timeIndex';
    if (_medicationStatus.containsKey(key)) {
      return _medicationStatus[key]!;
    }
    return med['taken'][timeIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF2563EB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header & Calendar ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Minha Saúde',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _daysOfWeek.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentDayIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _currentDayIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 64,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white,
                              border: Border.all(
                                color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _daysOfWeek[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${17 + index}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 4),
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Mood
                  const Text('Como você está hoje?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _moodOptions.map((mood) {
                      final isSelected = _selectedMood == mood['id'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMood = mood['id']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? mood['bgColor'] : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? mood['color'].withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(mood['icon'], size: 32, color: isSelected ? mood['color'] : const Color(0xFF94A3B8)),
                                const SizedBox(height: 8),
                                Text(
                                  mood['label'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? mood['color'] : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Symptoms
                  const Text('Sintomas rápidos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _symptoms.map((sym) {
                      final isSelected = _selectedSymptoms.contains(sym['id']);
                      return GestureDetector(
                        onTap: () => _toggleSymptom(sym['id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 4))]
                                : null,
                          ),
                          child: Text(
                            sym['label'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Medications
                  const Text('Meus Medicamentos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  Column(
                    children: _medications.map((med) {
                      final Color medColor = med['color'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: medColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: medColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med['name'],
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    med['dosage'],
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(med['times'].length, (index) {
                                      final isTaken = _isMedicationTaken(med, index);
                                      return GestureDetector(
                                        onTap: () => _toggleMedication(med['id'], index),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isTaken ? const Color(0xFF10B981) : const Color(0xFFF8FAFC),
                                            border: Border.all(color: isTaken ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: isTaken
                                                ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))]
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 16, height: 16,
                                                decoration: BoxDecoration(
                                                  color: isTaken ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                                                  border: Border.all(color: isTaken ? Colors.white : const Color(0xFF94A3B8), width: 1.5),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: isTaken ? const Icon(Icons.check_rounded, size: 10, color: Colors.white) : null,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                med['times'][index],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isTaken ? Colors.white : const Color(0xFF334155),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
