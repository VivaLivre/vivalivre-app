import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import 'package:viva_livre_app/core/presentation/widgets/custom_text_field.dart';

class SymptomSearchModal extends StatefulWidget {
  final List<String> availableSymptoms;
  final Function(List<String>, String) onAdd;

  const SymptomSearchModal({
    required this.availableSymptoms,
    required this.onAdd,
  });

  @override
  State<SymptomSearchModal> createState() => SymptomSearchModalState();
}

class SymptomSearchModalState extends State<SymptomSearchModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
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
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim();
    final bool showCustomAdd =
        query.isNotEmpty &&
        !widget.availableSymptoms.any(
          (s) => s.toLowerCase() == query.toLowerCase(),
        );

    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Lista de Chips ──
          Flexible(
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
                        selectedColor: const Color(
                          0xFF2563EB,
                        ).withValues(alpha: 0.2),
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
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2563EB).withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
                            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2563EB).withValues(alpha: 0.3) : const Color(0xFFBFDBFE)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add_circle_outline_rounded,
                                color: Color(0xFF2563EB),
                              ),
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
          
          // ── Observações ──
          Padding(
            padding: const EdgeInsets.only(
              left: 24, 
              right: 24, 
              top: 16, 
              bottom: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Observações (Opcional)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  hintText: 'Algum detalhe adicional?',
                ),
              ],
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
                          widget.onAdd(selectedSymptoms, _notesCtrl.text.trim());
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300,
                    disabledForegroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.grey.shade600,
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
} // fecha SymptomSearchModalState

// ═════════════════════════════════════════════════════════════════════════════
//  _BathroomExtrasModal — "E mais alguma coisa?"
//  Modal compacto que permite registar sintomas comuns junto com a ida
//  ao banheiro, tudo num único documento Firestore.
// ═════════════════════════════════════════════════════════════════════════════
