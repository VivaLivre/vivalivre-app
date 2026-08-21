import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _passwordScore = 0;

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
  final _heightFormatter = _HeightInputFormatter();
  String? _selectedCondition;

  // -- Step 4: Comorbidades --
  final _step4FormKey = GlobalKey<FormState>();
  final TextEditingController _comorbitySearchController = TextEditingController();
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
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordScore);
  }

  void _updatePasswordScore() {
    final password = _passwordController.text;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    setState(() {
      _passwordScore = score;
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordScore);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cpfController.dispose();
    _customConditionController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _comorbitySearchController.dispose();
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
        setState(() => _currentStep += 1);
      }
    } else if (_currentStep == 3) {
      if (_step4FormKey.currentState?.validate() ?? false) {
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
    
    final weightStr = _weightController.text.trim();
    final heightStr = _heightController.text.trim();
    final weightRaw = weightStr.isNotEmpty ? double.tryParse(weightStr) : null;
    final heightRaw = heightStr.isNotEmpty ? double.tryParse(heightStr) : null;
    
    // Converter para double (inteiro)
    final weight = weightRaw;
    final height = heightRaw;

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
                          label: _currentStep == 3 ? 'Finalizar Registo' : 'Continuar',
                          isLoading: isLoading && _currentStep == 3,
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
                          textCapitalization: TextCapitalization.words,
                          prefixIcon: Icon(Icons.person_outline, color: iconColor),
                          textInputAction: TextInputAction.next,
                          maxLength: 100,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Informe o seu nome.';
                            if (value.trim().length < 3) return 'Pelo menos 3 caracteres.';
                            final nameRegex = RegExp(r"^[\p{L}\s\-']+$", unicode: true);
                            if (!nameRegex.hasMatch(value)) return 'O nome contém caracteres inválidos.';
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
                          maxLength: 255,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Informe o seu e-mail.';
                            if (!value.contains('@')) return 'E-mail inválido.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          hintText: 'Palavra-passe',
                          prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                          textInputAction: TextInputAction.next,
                          maxLength: 100,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: iconColor),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          onChanged: _checkPasswordStrength,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Informe a sua senha.';
                            if (_passwordScore < 3) return 'Senha muito fraca. Use letras, números e no mínimo 8 caracteres.';
                            return null;
                          },
                        ),
                        if (_passwordController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4, right: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _passwordScore >= 1 ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _passwordScore >= 2 ? Colors.orange : Colors.grey.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _passwordScore >= 3 ? Colors.amber : Colors.grey.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _passwordScore >= 4 ? Colors.green : Colors.grey.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          hintText: 'Confirmar palavra-passe',
                          prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                          textInputAction: TextInputAction.done,
                          maxLength: 100,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: iconColor),
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
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

                // STEP 4: COMORBIDADES
                Step(
                  title: Text('Comorbidades', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
                  isActive: _currentStep >= 3,
                  content: Form(
                    key: _step4FormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Adicione outras condições médicas (opcional)',
                          style: TextStyle(color: iconColor, fontSize: 14),
                        ),
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
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                                          // Ordenar a lista após adição para manter organizado
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
                                                if (checked) {
                                                  _selectedComorbidities.add(comorbity);
                                                } else {
                                                  _selectedComorbidities.remove(comorbity);
                                                }
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
          );
        },
      ),
    );
  }
}

class _HeightInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return newValue.copyWith(text: '');
    if (text.length == 1) return newValue.copyWith(text: text);
    if (text.length == 2) {
      return newValue.copyWith(
        text: '${text[0]},${text[1]}', 
        selection: const TextSelection.collapsed(offset: 3)
      );
    }
    if (text.length >= 3) {
      String formatted = '${text[0]},${text.substring(1, 3)}';
      return newValue.copyWith(
        text: formatted, 
        selection: const TextSelection.collapsed(offset: 4)
      );
    }
    return newValue;
  }
}
