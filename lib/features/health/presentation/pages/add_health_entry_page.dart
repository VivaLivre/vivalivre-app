import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/presentation/health_bloc.dart';

class AddHealthEntryPage extends StatefulWidget {
  const AddHealthEntryPage({super.key});

  @override
  State<AddHealthEntryPage> createState() => _AddHealthEntryPageState();
}

class _AddHealthEntryPageState extends State<AddHealthEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  final List<String> _selectedSymptoms = [];
  String _severity = 'Leve';
  String _type = 'sintoma';

  // ── Paleta (mantida da HealthPage) ──
  static const Color _kBlue = Color(0xFF2563EB);
  static const Color _kText = Color(0xFF0F172A);
  static const Color _kSubText = Color(0xFF64748B);
  static const Color _kBg = Color(0xFFF8FAFC);

  final List<String> _severityOptions = ['Leve', 'Moderada', 'Grave'];

  final List<String> _symptomsOptions = [
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    Vibration.vibrate(duration: 60);

    // Guard defensivo — evita bang operator em currentState
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    // Validação extra: pelo menos 1 sintoma selecionado
    if (_selectedSymptoms.isEmpty) return;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão expirada. Por favor, faça login novamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final entry = HealthEntry(
      id: '', // Firestore gera o ID via .add()
      userId: userId,
      symptoms: List<String>.from(_selectedSymptoms),
      severity: _severity,
      notes: _notesController.text.trim(),
      timestamp: DateTime.now(),
      type: _type,
    );

    context.read<HealthBloc>().add(AddHealthEntry(entry));
    Navigator.pop(context);
  }

  /// Calcula automaticamente a gravidade com base nos sintomas selecionados.
  /// É chamado sempre que o utilizador toca num chip de sintoma.
  /// Regra principal: QUALQUER sintoma grave = Grave, independente da quantidade.
  /// O utilizador ainda pode ajustar manualmente no seletor de gravidade.
  void _autoCalculateSeverity() {
    // Sintomas que disparam "Grave" imediatamente (mesmo que seja apenas 1)
    const severeSymptoms = [
      'Sangue nas Fezes', 'Fadiga Extrema', 'Febre', 'Incontinência Fecal',
      'Desidratação', 'Perda de Peso', 'Anemia', 'Desmaios', 'Convulsões',
      'Dor Intensa no Peito', 'Dificuldade para Respirar', 'Febre Alta',
    ];

    final hasSevere = _selectedSymptoms.any((s) => severeSymptoms.contains(s));

    final String newSeverity;
    if (hasSevere) {
      // 1 sintoma grave já é suficiente para Grave
      newSeverity = 'Grave';
    } else if (_selectedSymptoms.length >= 3) {
      newSeverity = 'Moderada';
    } else if (_selectedSymptoms.isNotEmpty) {
      newSeverity = 'Leve';
    } else {
      newSeverity = 'Leve';
    }

    if (newSeverity != _severity) {
      setState(() => _severity = newSeverity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: _kText),
          title: const Text(
            'Registar Sintoma / Crise',
            style: TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _submitForm,
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: _kBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [

              // ── Tipo de Registo ──
              _SectionLabel('Tipo de Registo'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TypeChip(
                    label: 'Sintoma',
                    icon: Icons.healing_rounded,
                    color: const Color(0xFFF59E0B),
                    isSelected: _type == 'sintoma',
                    onTap: () => setState(() => _type = 'sintoma'),
                  ),
                  const SizedBox(width: 12),
                  _TypeChip(
                    label: 'Banheiro',
                    icon: Icons.wc_rounded,
                    color: _kBlue,
                    isSelected: _type == 'banheiro',
                    onTap: () => setState(() => _type = 'banheiro'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Gravidade ──
              _SectionLabel('Gravidade'),
              const SizedBox(height: 12),
              Row(
                children: _severityOptions.map((option) {
                  final isSelected = _severity == option;
                  final color = option == 'Leve'
                      ? const Color(0xFF10B981)
                      : option == 'Moderada'
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _severity = option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            option,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? color : _kSubText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // ── Sintomas ──
              _SectionLabel('Sintomas'),
              const SizedBox(height: 4),
              const Text(
                'Selecione pelo menos um.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              FormField<List<String>>(
                initialValue: _selectedSymptoms,
                validator: (value) =>
                    (value == null || value.isEmpty)
                        ? 'Selecione pelo menos um sintoma.'
                        : null,
                builder: (FormFieldState<List<String>> state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _symptomsOptions.map((symptom) {
                          final isSelected = _selectedSymptoms.contains(symptom);
                          return FilterChip(
                            label: Text(symptom),
                            selected: isSelected,
                            onSelected: (selected) {
                              Vibration.vibrate(duration: 30);
                              setState(() {
                                if (selected) {
                                  _selectedSymptoms.add(symptom);
                                } else {
                                  _selectedSymptoms.remove(symptom);
                                }
                                // Recalcula a gravidade automaticamente a cada toque.
                                _autoCalculateSeverity();
                              });
                              state.didChange(_selectedSymptoms);
                            },
                            // ── Cores originais preservadas ──
                            selectedColor: _kBlue.withValues(alpha: 0.2),
                            checkmarkColor: _kBlue,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? _kBlue : const Color(0xFFE2E8F0),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? _kBlue : _kText,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── Notas ──
              _SectionLabel('Observações'),
              const SizedBox(height: 4),
              const Text(
                'Opcional. Máximo de 500 caracteres.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 5,
                // SANITIZAÇÃO: limite de 500 caracteres enforçado no input
                maxLength: 500,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                decoration: InputDecoration(
                  hintText: 'Descreva como se sente, contexto, etc.',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _kBlue, width: 2),
                  ),
                  counterStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ),
              const SizedBox(height: 32),

              // ── Botão Guardar ──
              SafeArea(
                bottom: true,
                child: BlocBuilder<HealthBloc, HealthState>(
                  builder: (context, state) {
                    final isSaving = state is HealthEntryAdding;
                    return SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Guardar Registo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ──

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : const Color(0xFF94A3B8), size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
