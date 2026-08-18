import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_primary_button.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_text_field.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';
import 'package:viva_livre_app/core/theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _currentStep = 0;

  // -- Step 1: Conta --
  final _step1FormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // -- Step 2: Dados Pessoais --
  final _step2FormKey = GlobalKey<FormState>();
  final TextEditingController _cpfController = TextEditingController();
  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##', 
    filter: {"#": RegExp(r'[0-9]')},
  );
  DateTime? _selectedDate;
  String? _selectedGender;

  // -- Step 3: Ficha Clínica --
  final _step3FormKey = GlobalKey<FormState>();
  final TextEditingController _customConditionController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String? _selectedCondition;
  final Set<String> _selectedComorbidities = {};

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Regex simples para validar formato de e-mail
  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');

  // Listas de opções
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

  static const List<String> _comorbiditiesList = [
    'Diabetes',
    'Hipertensão',
    'Hipotireoidismo',
    'Nenhuma',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cpfController.dispose();
    _customConditionController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_step1FormKey.currentState?.validate() ?? false) {
        setState(() => _currentStep += 1);
      }
    } else if (_currentStep == 1) {
      if (_step2FormKey.currentState?.validate() ?? false) {
        if (_selectedDate == null) {
          _showSnack('Selecione a sua data de nascimento.');
          return;
        }
        if (_selectedGender == null) {
          _showSnack('Selecione o seu sexo.');
          return;
        }
        setState(() => _currentStep += 1);
      }
    } else if (_currentStep == 2) {
      if (_step3FormKey.currentState?.validate() ?? false) {
        if (_selectedCondition == null) {
          _showSnack('Selecione a sua condição clínica.');
          return;
        }
        if (_selectedCondition == 'Outra' && _customConditionController.text.trim().isEmpty) {
          _showSnack('Descreva a sua condição clínica.');
          return;
        }
        _onRegisterPressed();
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      Navigator.pop(context);
    }
  }

  void _onRegisterPressed() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final cpf = _cpfFormatter.getUnmaskedText(); // Remove máscara
    final dateOfBirth = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final gender = _selectedGender!;
    
    final weightStr = _weightController.text.replaceAll(',', '.').trim();
    final heightStr = _heightController.text.replaceAll(',', '.').trim();
    final weight = weightStr.isNotEmpty ? double.tryParse(weightStr) : null;
    final height = heightStr.isNotEmpty ? double.tryParse(heightStr) : null;

    final clinicalCondition = _selectedCondition == 'Outra' ? _customConditionController.text.trim() : _selectedCondition!;
    final comorbidities = _selectedComorbidities.toList();

    context.read<AuthBloc>().add(AuthRegisterRequested(
      name: name,
      email: email,
      password: password,
      cpf: cpf,
      dateOfBirth: dateOfBirth,
      gender: gender,
      weight: weight,
      height: height,
      clinicalCondition: clinicalCondition,
      comorbidities: comorbidities,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC);
    final textDark = isDark ? AppColors.darkText : const Color(0xFF1E293B);
    final iconColor = isDark ? Colors.white54 : const Color(0xFF94A3B8);
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Identidade DII',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red.shade600,
              ),
            );
          } else if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Conta criada com sucesso!'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: isLoading ? null : _onStepContinue,
              onStepCancel: isLoading ? null : _onStepCancel,
              physics: const ClampingScrollPhysics(),
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomPrimaryButton(
                          onPressed: isLoading ? null : details.onStepContinue,
                          label: _currentStep == 2 ? 'Finalizar Registo' : 'Continuar',
                          isLoading: isLoading && _currentStep == 2,
                          loadingLabel: 'A criar conta...',
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              'Voltar',
                              style: TextStyle(
                                color: textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                // STEP 1: CONTA
                Step(
                  title: Text('Conta', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: Form(
                    key: _step1FormKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _nameController,
                          hintText: 'Nome Completo',
                          prefixIcon: Icon(Icons.person_outline, color: iconColor),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Informe o seu nome.';
                            if (value.trim().length < 3) return 'Pelo menos 3 caracteres.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hintText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined, color: iconColor),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Informe o seu e-mail.';
                            if (!_emailRegex.hasMatch(value.trim())) return 'Formato inválido.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          hintText: 'Palavra-passe (mín. 6 chars)',
                          prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: iconColor),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Informe a sua senha.';
                            if (value.trim().length < 6) return 'Mínimo de 6 caracteres.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          hintText: 'Confirmar palavra-passe',
                          prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: iconColor),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Confirme a sua senha.';
                            if (value != _passwordController.text) return 'As senhas não coincidem.';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // STEP 2: DADOS PESSOAIS
                Step(
                  title: Text('Dados Pessoais', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: Form(
                    key: _step2FormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        // CPF (Precisa de inputFormatter)
                        TextFormField(
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [_cpfFormatter],
                          style: TextStyle(color: textDark),
                          decoration: InputDecoration(
                            hintText: 'CPF',
                            hintStyle: TextStyle(color: iconColor),
                            prefixIcon: Icon(Icons.badge_outlined, color: iconColor),
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Informe o seu CPF';
                            if (_cpfFormatter.getUnmaskedText().length != 11) return 'CPF inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // Data de Nascimento
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, color: iconColor),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedDate == null 
                                      ? 'Data de Nascimento' 
                                      : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                                  style: TextStyle(
                                    color: _selectedDate == null ? iconColor : textDark,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Sexo
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            isExpanded: true,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person_outline, color: iconColor),
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                            hint: Text('Sexo', style: TextStyle(color: iconColor)),
                            dropdownColor: cardColor,
                            items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g, style: TextStyle(color: textDark)))).toList(),
                            onChanged: (val) => setState(() => _selectedGender = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // STEP 3: FICHA CLÍNICA
                Step(
                  title: Text('Ficha Clínica', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
                  isActive: _currentStep >= 2,
                  content: Form(
                    key: _step3FormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        // Condição Clínica
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCondition,
                            isExpanded: true,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.medical_information_outlined, color: iconColor),
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                            hint: Text('Condição Clínica Principal', style: TextStyle(color: iconColor)),
                            dropdownColor: cardColor,
                            items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: textDark)))).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCondition = val;
                                if (val != 'Outra') _customConditionController.clear();
                              });
                            },
                          ),
                        ),
                        if (_selectedCondition == 'Outra') ...[
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _customConditionController,
                            hintText: 'Descreva a sua condição',
                            prefixIcon: Icon(Icons.edit_outlined, color: iconColor),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Descreva a sua condição.' : null,
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Peso e Altura lado a lado
                        Row(
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
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                hintText: 'Altura (m)',
                                prefixIcon: Icon(Icons.height_outlined, color: iconColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Comorbidades
                        Text(
                          'Comorbidades / Outras Condições',
                          style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: _comorbiditiesList.map((comorbity) {
                              return CheckboxListTile(
                                title: Text(comorbity, style: TextStyle(color: textDark)),
                                value: _selectedComorbidities.contains(comorbity),
                                checkColor: Colors.white,
                                activeColor: const Color(0xFF2563EB),
                                onChanged: (checked) {
                                  setState(() {
                                    if (comorbity == 'Nenhuma' && checked == true) {
                                      _selectedComorbidities.clear();
                                      _selectedComorbidities.add('Nenhuma');
                                    } else {
                                      _selectedComorbidities.remove('Nenhuma');
                                      if (checked == true) {
                                        _selectedComorbidities.add(comorbity);
                                      } else {
                                        _selectedComorbidities.remove(comorbity);
                                      }
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
