import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_primary_button.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_text_field.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';
import 'package:viva_livre_app/features/profile/data/repositories/profile_repository.dart';
import 'package:viva_livre_app/core/theme/app_colors.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _cpfController = TextEditingController();
  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##', 
    filter: {"#": RegExp(r'[0-9]')},
  );
  DateTime? _selectedDate;
  String? _selectedGender;

  final TextEditingController _customConditionController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String? _selectedCondition;

  final TextEditingController _comorbitySearchController = TextEditingController();
  final Set<String> _selectedComorbidities = {};

  bool _isLoading = false;

  static const List<String> _conditions = [
    'Doença de Crohn',
    'Retocolite Ulcerativa',
    'Pancolite',
    'Proctite Ulcerativa',
    'Colite Indeterminada',
    'Síndrome do Intestino Irritável (SII)',
    'Doença Celíaca',
    'Incontinência Fecal',
    'Gestante',
    'Outra',
  ];

  static const List<String> _genders = [
    'Masculino',
    'Feminino',
    'Outro',
    'Prefiro não dizer',
  ];

  final List<String> _comorbiditiesList = [
    'Ansiedade',
    'Artrite Reumatoide',
    'Asma',
    'Cálculo Renal',
    'Colesterol Alto',
    'Depressão',
    'Diabetes',
    'Doença Celíaca',
    'Endometriose',
    'Fibromialgia',
    'Gastrite',
    'Hipertensão',
    'Hipotireoidismo',
    'Lúpus',
    'Obesidade',
    'Osteoporose',
    'Síndrome de Sjögren',
    'Trombose',
  ];

  @override
  void dispose() {
    _cpfController.dispose();
    _customConditionController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _comorbitySearchController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_cpfController.text.trim().isEmpty || _cpfController.text.length < 14) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, informe um CPF válido.'), backgroundColor: AppColors.error));
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione a sua data de nascimento.'), backgroundColor: AppColors.error));
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione o seu género.'), backgroundColor: AppColors.error));
      return;
    }
    if (_selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione a sua condição clínica.'), backgroundColor: AppColors.error));
      return;
    }
    if (_selectedCondition == 'Outra' && _customConditionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, especifique a sua condição clínica.'), backgroundColor: AppColors.error));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) throw Exception('Não autenticado');
      
      final email = authState.user.email;
      final clinicalCondition = _selectedCondition == 'Outra' ? _customConditionController.text.trim() : _selectedCondition!;
      final weight = double.tryParse(_weightController.text.trim());
      final height = int.tryParse(_heightController.text.trim());
      final cpf = _cpfController.text.trim().isEmpty ? null : _cpfController.text.trim();

      final profileRepo = RepositoryProvider.of<ProfileRepository>(context);
      final updatedUser = await profileRepo.updateProfile(
        email: email,
        height: height,
        weight: weight,
        birthDate: _selectedDate,
        gender: _selectedGender,
        cpf: cpf,
        clinicalCondition: clinicalCondition,
        comorbidities: _selectedComorbidities.toList(),
      );

      if (mounted) {
        if (updatedUser != null) {
          context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil completado com sucesso!'), backgroundColor: AppColors.successText),
          );
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          throw Exception('Resposta vazia do servidor.');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final textDark = theme.colorScheme.onSurface;
    final iconColor = const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Completar Perfil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Falta pouco para começarmos!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Preenche os dados em baixo para completares o teu perfil e acederes à plataforma.',
                  style: TextStyle(fontSize: 15, color: textDark.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 32),

                // -- Dados Pessoais --
                const Text('Dados Pessoais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _cpfController,
                  hintText: 'CPF (Obrigatório)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [_cpfFormatter],
                  prefixIcon: Icon(Icons.badge_outlined, color: iconColor),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty || v.length < 14) {
                      return 'CPF inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Data Nascimento e Género
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: TextEditingController(
                              text: _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : '',
                            ),
                            hintText: 'Data Nasc.',
                            prefixIcon: Icon(Icons.calendar_today, color: iconColor),
                            validator: (v) => _selectedDate == null ? 'Obrigatório' : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        hint: Text('Género', style: TextStyle(color: iconColor)),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          prefixIcon: Icon(Icons.person_outline, color: iconColor),
                        ),
                        dropdownColor: cardColor,
                        items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) => setState(() => _selectedGender = val),
                        validator: (v) => v == null ? 'Obrigatório' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // -- Ficha Clínica --
                const Text('Ficha Clínica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCondition,
                  hint: Text('Condição Clínica Principal', style: TextStyle(color: iconColor)),
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: Icon(Icons.medical_services_outlined, color: iconColor),
                  ),
                  dropdownColor: cardColor,
                  items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() {
                    _selectedCondition = val;
                    if (val != 'Outra') {
                      _customConditionController.clear();
                    }
                  }),
                  validator: (v) => v == null ? 'A condição é obrigatória' : null,
                ),
                if (_selectedCondition == 'Outra') ...[
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _customConditionController,
                    hintText: 'Especificar condição',
                    prefixIcon: Icon(Icons.edit_outlined, color: iconColor),
                    validator: (v) {
                      if (_selectedCondition == 'Outra' && (v == null || v.trim().isEmpty)) {
                        return 'Especifique a sua condição.';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                
                // Peso e Altura
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        hintText: 'Peso (kg)',
                        prefixIcon: Icon(Icons.monitor_weight_outlined, color: iconColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        hintText: 'Altura (cm)',
                        prefixIcon: Icon(Icons.height_outlined, color: iconColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // -- Comorbidades --
                const Text('Comorbidades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Adicione outras condições médicas (opcional)', style: TextStyle(color: iconColor, fontSize: 14)),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _comorbitySearchController,
                  hintText: 'Pesquisar condição...',
                  prefixIcon: Icon(Icons.search, color: iconColor),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                  child: Builder(
                    builder: (context) {
                      final query = _comorbitySearchController.text.trim().toLowerCase();
                      final filtered = _comorbiditiesList.where((c) => c.toLowerCase().contains(query)).toList();
                      final exactMatch = _comorbiditiesList.any((c) => c.toLowerCase() == query);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (query.isNotEmpty && !exactMatch)
                            ListTile(
                              leading: const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB)),
                              title: Text('Adicionar "$query"', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                              onTap: () {
                                setState(() {
                                  final newC = _comorbitySearchController.text.trim();
                                  _comorbiditiesList.add(newC);
                                  _selectedComorbidities.add(newC);
                                  _comorbitySearchController.clear();
                                  _comorbiditiesList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                                });
                              },
                            ),
                          if (filtered.isEmpty && query.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Nenhuma condição listada'),
                            ),
                          if (filtered.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: filtered.map((comorbity) {
                                  final isSelected = _selectedComorbidities.contains(comorbity);
                                  return FilterChip(
                                    label: Text(comorbity),
                                    selected: isSelected,
                                    showCheckmark: false,
                                    selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                    backgroundColor: Colors.transparent,
                                    labelStyle: TextStyle(
                                      color: isSelected ? const Color(0xFF2563EB) : textDark,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      side: BorderSide(
                                        color: isSelected ? const Color(0xFF2563EB) : iconColor.withValues(alpha: 0.3),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    onSelected: (checked) {
                                      setState(() {
                                        if (checked) _selectedComorbidities.add(comorbity);
                                        else _selectedComorbidities.remove(comorbity);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }
                  ),
                ),

                const SizedBox(height: 48),
                CustomPrimaryButton(
                  onPressed: _submitProfile,
                  label: 'Concluir Registo',
                  isLoading: _isLoading,
                  loadingLabel: 'A guardar...',
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
