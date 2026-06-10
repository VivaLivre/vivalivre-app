import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  // -- Controllers --
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _customConditionController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // -- State --
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedCondition;

  // Regex simples para validar formato de e-mail
  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');

  // Lista de condições clínicas comuns no Brasil
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _customConditionController.dispose();
    super.dispose();
  }

  // -- Lógica de Registo --
  void _onRegisterPressed() {
    // 1. Valida o formulário
    // DEFESA: currentState pode ser null em hot-restart ou rebuild rápido.
    // Evitamos o bang operator (!) usando verificação explícita prévia.
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    // 2. Valida selecção de condição
    if (_selectedCondition == null) {
      _showSnack('Selecione a sua condição clínica.');
      return;
    }

    // 3. Se escolheu "Outra", valida o campo customizado
    if (_selectedCondition == 'Outra' &&
        _customConditionController.text.trim().isEmpty) {
      _showSnack('Descreva a sua condição clínica.');
      return;
    }

    // 4. Dispara o evento real no AuthBloc
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    context.read<AuthBloc>().add(AuthRegisterRequested(name, email, password));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  // -- UI Builders --
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC);
    final textDark = isDark ? AppColors.darkText : const Color(0xFF1E293B);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF64748B);
    final iconColor = isDark ? Colors.white54 : const Color(0xFF94A3B8);
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
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
          final bool canSubmit = !isLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 8.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // -- Header --
                      Text(
                        'Identidade DII',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crie o seu perfil de paciente para validar o seu Cartão de uso prioritário.',
                        style: TextStyle(
                          fontSize: 15,
                          color: textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // -- Dados Pessoais --
                      _SectionTitle('Dados Pessoais', color: textDark),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _nameController,
                        enabled: !isLoading,
                        hintText: 'Nome Completo',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: iconColor,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o seu nome.';
                          }
                          if (value.trim().length < 3) {
                            return 'O nome precisa ter pelo menos 3 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _emailController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'E-mail',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: iconColor,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o seu e-mail.';
                          }
                          if (!_emailRegex.hasMatch(value.trim())) {
                            return 'Formato de e-mail inválido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _passwordController,
                        enabled: !isLoading,
                        obscureText: _obscurePassword,
                        hintText: 'Palavra-passe (mín. 6 caracteres)',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: iconColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: iconColor,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a sua senha.';
                          }
                          if (value.trim().length < 6) {
                            return 'A senha precisa ter pelo menos 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _confirmPasswordController,
                        enabled: !isLoading,
                        obscureText: _obscureConfirmPassword,
                        hintText: 'Confirmar palavra-passe',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: iconColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: iconColor,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword = !_obscureConfirmPassword,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Confirme a sua senha.';
                          }
                          if (value != _passwordController.text) {
                            return 'As senhas não coincidem.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // -- Condição Clínica (Dropdown) --
                      _SectionTitle('Condição Clínica', color: textDark),
                      const SizedBox(height: 8),
                      Text(
                        'Selecione a condição que melhor se aplica ao seu caso.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),

                      IgnorePointer(
                        ignoring: isLoading,
                        child: Opacity(
                          opacity: isLoading ? 0.5 : 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCondition,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.medical_information_outlined,
                                  color: iconColor,
                                ),
                                filled: true,
                                fillColor: cardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              hint: Text(
                                'Selecione a sua condição',
                                style: TextStyle(color: iconColor),
                              ),
                              dropdownColor: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              items: _conditions.map((condition) {
                                return DropdownMenuItem<String>(
                                  value: condition,
                                  child: Text(
                                    condition,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: textDark,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCondition = value;
                                  if (value != 'Outra') {
                                    _customConditionController.clear();
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      // Campo customizado para "Outra"
                      if (_selectedCondition == 'Outra') ...[
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _customConditionController,
                          enabled: !isLoading,
                          hintText: 'Descreva a sua condição',
                          prefixIcon: Icon(
                            Icons.edit_outlined,
                            color: iconColor,
                          ),
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (_selectedCondition == 'Outra' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Descreva a sua condição clínica.';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 40),

                      // -- Botão Finalizar (com loading inline) --
                      Theme(
                        data: Theme.of(context).copyWith(
                          elevatedButtonTheme: ElevatedButtonThemeData(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              disabledBackgroundColor: const Color(0xFFCBD5E1),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: canSubmit ? 4 : 0,
                            ),
                          ),
                        ),
                        child: CustomPrimaryButton(
                          onPressed: canSubmit ? _onRegisterPressed : null,
                          label: 'Finalizar Registo',
                          isLoading: isLoading,
                          loadingLabel: 'A criar conta...',
                          child: isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'A criar conta...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Finalizar Registo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// -- Widget auxiliar para títulos de secção --
class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionTitle(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}
