import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/presentation/health_bloc.dart';

class AddHealthEntryPage extends StatefulWidget {
  const AddHealthEntryPage({super.key});

  @override
  State<AddHealthEntryPage> createState() => _AddHealthEntryPageState();
}

class _AddHealthEntryPageState extends State<AddHealthEntryPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String _symptoms = '';
  String _severity = 'Leve';
  String _notes = '';

  final List<String> _severityOptions = ['Leve', 'Moderada', 'Grave'];
  
  final List<String> _symptomsOptions = [
    'Dor Abdominal', 'Diarreia', 'Sangue nas Fezes', 'Fadiga Extrema',
    'Febre', 'Náusea/Vómito', 'Gases/Inchaço', 'Perda de Apetite', 'Dores Articulares'
  ];
  final List<String> _selectedSymptomsList = [];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newEntry = HealthEntry(
        id: DateTime.now().toIso8601String(),
        date: _selectedDate,
        symptoms: _symptoms,
        severity: _severity,
        notes: _notes,
      );
      context.read<HealthBloc>().add(AddHealthEntry(newEntry));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).unfocus();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Novo Sintoma/Crise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              const Text('Data:', style: TextStyle(fontWeight: FontWeight.bold)),
              ListTile(
                title: Text('${_selectedDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16.0),

              const Text('Sintomas:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              FormField<List<String>>(
                initialValue: _selectedSymptomsList,
                validator: (value) => (value == null || value.isEmpty) ? 'Selecione pelo menos um sintoma' : null,
                builder: (FormFieldState<List<String>> state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _symptomsOptions.map((symptom) {
                          return FilterChip(
                            label: Text(symptom),
                            selected: _selectedSymptomsList.contains(symptom),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSymptomsList.add(symptom);
                                } else {
                                  _selectedSymptomsList.remove(symptom);
                                }
                                _symptoms = _selectedSymptomsList.join(', ');
                              });
                              state.didChange(_selectedSymptomsList);
                            },
                            selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
                            checkmarkColor: const Color(0xFF2563EB),
                          );
                        }).toList(),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16.0),

              const Text('Gravidade:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                value: _severity,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _severityOptions.map((String severity) {
                  return DropdownMenuItem<String>(
                    value: severity,
                    child: Text(severity),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _severity = newValue;
                    });
                  }
                },
                validator: (value) => (value == null || value.isEmpty) ? 'Por favor, selecione a gravidade' : null,
              ),
              const SizedBox(height: 16.0),

              const Text('Observações:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              TextFormField(
                decoration: const InputDecoration(hintText: 'Notas adicionais', border: OutlineInputBorder()),
                onChanged: (value) => _notes = value,
                maxLines: 5,
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}
