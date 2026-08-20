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
import 'package:dio/dio.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  int _currentStep = 0;
  
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

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

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_step1FormKey.currentState?.validate() ?? false) {
        if (_cpfController.text.trim().isEmpty || _cpfController.text.length < 14) {
          _showSnack('Por favor, informe um CPF válido.');
          return;
        }
        if (_selectedDate == null) {
          _showSnack('Selecione a sua data de nascimento.');
          return;
        }
        if (_selectedGender == null) {
          _showSnack('Selecione o seu género.');
          return;
        }
        if (_passwordController.text.isNotEmpty) {
          if (_passwordController.text.length < 6) {
            _showSnack('A palavra-passe deve ter pelo menos 6 caracteres.');
            return;
          }
          if (_passwordController.text != _confirmPasswordController.text) {
            _showSnack('As palavras-passe não coincidem.');
            return;
          }
        }
        setState(() => _currentStep += 1);
      }
    } else if (_currentStep == 1) {
      if (_step2FormKey.currentState?.validate() ?? false) {
        if (_selectedCondition == null) {
          _showSnack('Selecione a sua condição clínica.');
          return;
        }
        if (_selectedCondition == 'Outra' && _customConditionController.text.trim().isEmpty) {
          _showSnack('Por favor, especifique a sua condição clínica.');
          return;
        }
        setState(() => _currentStep += 1);
      }
    } else if (_currentStep == 2) {
      if (_step3FormKey.currentState?.validate() ?? false) {
        _submitProfile();
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _submitProfile() async {
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
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
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
        String errorMessage = 'Não foi possível atualizar o perfil.';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map<String, dynamic> && data['error'] != null) {
            errorMessage = data['error'];
          }
        } else {
          errorMessage = e.toString();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
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
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: _isLoading ? null : _onStepContinue,
          onStepCancel: _isLoading ? null : _onStepCancel,
          physics: const ClampingScrollPhysics(),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: CustomPrimaryButton(
                      onPressed: _isLoading ? null : details.onStepContinue,
                      label: _currentStep == 2 ? 'Finalizar Registo' : 'Continuar',
                      isLoading: _isLoading && _currentStep == 2,
                      loadingLabel: 'A guardar...',
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF94A3B8)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Voltar',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          steps: [
            // STEP 1: DADOS PESSOAIS
            Step(
              title: Text('Dados Pessoais', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
              isActive: _currentStep >= 0,
              content: Form(
                key: _step1FormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                            isExpanded: true,
                            dropdownColor: cardColor,
                            items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => _selectedGender = val),
                            validator: (v) => v == null ? 'Obrigatório' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Definir Palavra-passe (Opcional)',
                      style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Podes definir uma palavra-passe agora para poderes iniciar sessão com email/senha noutros dispositivos.',
                      style: TextStyle(color: iconColor, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Nova palavra-passe',
                      obscureText: _obscurePassword,
                      prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: iconColor,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirmar palavra-passe',
                      obscureText: _obscurePassword,
                      prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                    ),
                  ],
                ),
              ),
            ),

            // STEP 2: FICHA CLÍNICA
            Step(
              title: Text('Ficha Clínica', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
              isActive: _currentStep >= 1,
              content: Form(
                key: _step2FormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
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
                  ],
                ),
              ),
            ),

            // STEP 3: COMORBIDADES
            Step(
              title: Text('Comorbidades', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
              isActive: _currentStep >= 2,
              content: Form(
                key: _step3FormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
