import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_primary_button.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_text_field.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/presentation/health_bloc.dart';

class AddHealthEntryPage extends StatefulWidget {
  final HealthEntry? entryToEdit;

  const AddHealthEntryPage({super.key, this.entryToEdit});

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

  final List<String> _severityOptions = ['Leve', 'Observação', 'Grave'];

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
    'Dor Lombar', 'Cãibras', 'Espasmos Musculares', 'Parestesia/Formigueiro',
    'Dor de Garganta', 'Tosse', 'Falta de Ar', 'Olho Seco', 'Coceira/Prurido',
    'Dificuldade de Concentração',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      _notesController.text = widget.entryToEdit!.notes;
      _severity = widget.entryToEdit!.severity;
      _type = widget.entryToEdit!.type;
      // Filter out 'Ida ao Banheiro' just in case it was saved in the past
      _selectedSymptoms.addAll(
        widget.entryToEdit!.symptoms.where((s) => s != 'Ida ao Banheiro')
      );
    }
  }

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

    // Validação extra: pelo menos 1 sintoma selecionado SE for do tipo sintoma
    if (_type == 'sintoma' && _selectedSymptoms.isEmpty) return;

    final entry = HealthEntry(
      id: widget.entryToEdit?.id ?? '',
      userId: widget.entryToEdit?.userId ?? '',
      symptoms: List<String>.from(_selectedSymptoms),
      severity: _severity,
      notes: _notesController.text.trim(),
      timestamp: widget.entryToEdit?.timestamp ?? DateTime.now(),
      type: _type,
    );

    if (widget.entryToEdit != null) {
      context.read<HealthBloc>().add(UpdateHealthEntry(entry));
    } else {
      context.read<HealthBloc>().add(AddHealthEntry(entry));
    }
    Navigator.pop(context);
  }

  /// Calcula automaticamente a gravidade com base nos sintomas selecionados.
  /// É chamado sempre que o utilizador toca num chip de sintoma.
  /// Regra principal: QUALQUER sintoma grave = Grave, independente da quantidade.
  /// O utilizador ainda pode ajustar manualmente no seletor de gravidade.
  void _autoCalculateSeverity() {
    final newSeverity = HealthEntry.calculateSeverity(_selectedSymptoms);
    if (newSeverity != _severity) {
      setState(() => _severity = newSeverity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
          title: Text(
            widget.entryToEdit != null ? 'Editar Registo' : 'Registar Sintoma / Crise',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 18),
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

              // ── Gravidade (Automática) ──
              _SectionLabel('Gravidade (Calculada automaticamente)'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: (_severity == 'Leve'
                          ? const Color(0xFF10B981)
                          : _severity == 'Observação'
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _severity == 'Leve'
                        ? const Color(0xFF10B981)
                        : _severity == 'Observação'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444),
                    width: 2,
                  ),
                ),
                child: Text(
                  _severity,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _severity == 'Leve'
                        ? const Color(0xFF10B981)
                        : _severity == 'Observação'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Sintomas ──
              _SectionLabel('Sintomas'),
              const SizedBox(height: 4),
              Text(
                _type == 'sintoma' ? 'Selecione pelo menos um.' : 'Opcional para Ida ao Banheiro.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              FormField<List<String>>(
                initialValue: _selectedSymptoms,
                validator: (value) =>
                    (_type == 'sintoma' && (value == null || value.isEmpty))
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
                            // ── Cores dinâmicas para dark mode ──
                            selectedColor: _kBlue.withValues(alpha: 0.2),
                            checkmarkColor: _kBlue,
                            backgroundColor: Theme.of(context).cardColor,
                            side: BorderSide(
                              color: isSelected ? _kBlue : Theme.of(context).dividerColor,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? _kBlue : Theme.of(context).colorScheme.onSurface,
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
              CustomTextField(
                controller: _notesController,
                maxLines: 5,
                hintText: 'Descreva como se sente, contexto, etc.',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _notesController,
                  builder: (context, value, _) {
                    final count = value.text.length;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '$count/500',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    );
                  },
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
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          elevatedButtonTheme: ElevatedButtonThemeData(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kBlue,
                              disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        child: CustomPrimaryButton(
                          onPressed: _submitForm,
                          label: 'Guardar Registo',
                          isLoading: isSaving,
                          child: isSaving
                              ? const CustomLoadingIndicator(size: 22)
                              : const Text(
                                  'Guardar Registo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
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
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
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
            color: isSelected ? color.withValues(alpha: 0.12) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).dividerColor,
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
