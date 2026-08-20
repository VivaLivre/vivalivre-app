import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_text_field.dart';

class BathroomExtrasResult {
  final List<String> symptoms;
  final String notes;

  BathroomExtrasResult({required this.symptoms, required this.notes});
}

class BathroomExtrasModal extends StatefulWidget {
  const BathroomExtrasModal();

  @override
  State<BathroomExtrasModal> createState() => BathroomExtrasModalState();
}

class BathroomExtrasModalState extends State<BathroomExtrasModal> {
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
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        // viewInsets.bottom = teclado; viewPadding.bottom = barra de navegação
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            24,
      ),
      child: SingleChildScrollView(
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
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2563EB).withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.wc_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'E mais alguma coisa?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Opcional — tudo fica num registo só.',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
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
                selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                checkmarkColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).cardColor,
                side: BorderSide(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // ── Notas ──
          Text(
            'Observações (Opcional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _notesController,
            maxLines: 3,
            hintText: 'Algum detalhe adicional?',
          ),
          const SizedBox(height: 24),

          // ── Botões ──
          Row(
            children: [
              // Botão: Não, só isso
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(
                    context, 
                    BathroomExtrasResult(symptoms: [], notes: ''),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Não, só isso',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                    Navigator.pop(
                      context, 
                      BathroomExtrasResult(
                        symptoms: _selected, 
                        notes: _notesController.text.trim(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selected.isEmpty
                        ? 'Só a ida'
                        : 'Adicionar (${_selected.length})',
                    style: TextStyle(
                      color: Theme.of(context).cardColor,
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