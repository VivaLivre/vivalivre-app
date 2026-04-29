import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_primary_button.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_text_field.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';
import 'package:viva_livre_app/features/auth/presentation/widgets/auth_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // Regex simples para validar formato de e-mail
  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    // Valida o formulário antes de disparar o evento
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    context.read<AuthBloc>().add(AuthLoginRequested(email, password));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 32.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // -- Header --
                      const Icon(
                        Icons.health_and_safety_rounded,
                        size: 64,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bem-vindo de volta',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Faça login na sua conta do VivaLivre',
                        style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // -- Email --
                      const FieldLabel('Email'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _emailController,
                        enabled: !isLoading,
                        hintText: 'seu@email.com',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF94A3B8),
                        ),
                        keyboardType: TextInputType.emailAddress,
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
                      const SizedBox(height: 20),

                      // -- Senha --
                      const FieldLabel('Senha'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _passwordController,
                        enabled: !isLoading,
                        obscureText: _obscurePassword,
                        onFieldSubmitted: (_) => _onLoginPressed(),
                        hintText: 'Sua senha',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF94A3B8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF94A3B8),
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
                      const SizedBox(height: 6),

                      // -- Esqueceu a senha --
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Esqueceu a senha?'),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // -- Botao Entrar (com loading inline) --
                      CustomPrimaryButton(
                        onPressed: _onLoginPressed,
                        label: 'Entrar',
                        isLoading: isLoading,
                        loadingLabel: 'A entrar...',
                      ),
                      const SizedBox(height: 28),

                      // -- Divisor --
                      const OrDivider(),
                      const SizedBox(height: 24),


                      // -- Link Criar Conta --
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Não tem uma conta?',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    Navigator.pushNamed(context, '/register');
                                  },
                            child: const Text('Criar agora'),
                          ),
                        ],
                      ),
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
