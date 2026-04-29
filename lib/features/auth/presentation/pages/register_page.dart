import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_primary_button.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_text_field.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';

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
  final TextEditingController _customConditionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // -- State --
  bool _obscurePassword = true;
  String? _selectedCondition;
  File? _laudoFile;
  bool _isPdf = false;
  String? _fileName;

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
    _customConditionController.dispose();
    super.dispose();
  }

  // -- Lógica de Upload --
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _laudoFile = File(pickedFile.path);
        _isPdf = false;
        _fileName = pickedFile.name;
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _laudoFile = File(result.files.single.path!);
        _isPdf = true;
        _fileName = result.files.single.name;
      });
    }
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
    if (_selectedCondition == 'Outra' && _customConditionController.text.trim().isEmpty) {
      _showSnack('Descreva a sua condição clínica.');
      return;
    }

    // 4. Valida laudo
    if (_laudoFile == null) {
      _showSnack('O anexo do laudo médico é obrigatório.');
      return;
    }

    // 5. Dispara o evento real no AuthBloc (cria conta no Firebase)
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
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
                content: Text('Laudo recebido! Conta criada com sucesso.'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final bool canSubmit = _laudoFile != null && !isLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // -- Header --
                      const Text(
                        'Identidade DII',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crie o seu perfil de paciente para validar o seu Cartão de uso prioritário.',
                        style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.4),
                      ),
                      const SizedBox(height: 32),

                      // -- Dados Pessoais --
                      const _SectionTitle('Dados Pessoais'),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _nameController,
                        enabled: !isLoading,
                        hintText: 'Nome Completo',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF94A3B8)),
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
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8)),
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
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF94A3B8),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                      const SizedBox(height: 32),

                      // -- Condição Clínica (Dropdown) --
                      const _SectionTitle('Condição Clínica'),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecione a condição que melhor se aplica ao seu caso.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),

                      IgnorePointer(
                        ignoring: isLoading,
                        child: Opacity(
                          opacity: isLoading ? 0.5 : 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedCondition,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.medical_information_outlined, color: Color(0xFF94A3B8)),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              hint: const Text(
                                'Selecione a sua condição',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              items: _conditions.map((condition) {
                                return DropdownMenuItem<String>(
                                  value: condition,
                                  child: Text(
                                    condition,
                                    style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
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
                          prefixIcon: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8)),
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (_selectedCondition == 'Outra' && (value == null || value.trim().isEmpty)) {
                              return 'Descreva a sua condição clínica.';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 32),

                      // -- Comprovação Médica --
                      const _SectionTitle('Comprovação Médica'),
                      const SizedBox(height: 8),
                      const Text(
                        'O teu laudo será analisado para validar o teu Cartão de uso prioritário. Anexa uma foto clara ou o PDF original.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),

                      if (_laudoFile == null)
                        IgnorePointer(
                          ignoring: isLoading,
                          child: Opacity(
                            opacity: isLoading ? 0.5 : 1.0,
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _takePhoto,
                                    icon: const Icon(Icons.camera_alt_rounded),
                                    label: const Text('Tirar Foto'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      side: const BorderSide(color: Color(0xFF2563EB)),
                                      foregroundColor: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickPdf,
                                    icon: const Icon(Icons.picture_as_pdf_rounded),
                                    label: const Text('Selecionar PDF'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      side: const BorderSide(color: Color(0xFF2563EB)),
                                      foregroundColor: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _isPdf
                                    ? const Icon(Icons.description_rounded, color: Color(0xFF2563EB), size: 28)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        // DEFESA: capturamos _laudoFile em variável local para
                                        // eliminar o bang operator e documentar a premissa.
                                        child: Image.file(_laudoFile!, fit: BoxFit.cover),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Laudo anexado', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    Text(
                                      _fileName ?? 'Documento',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                onPressed: isLoading
                                    ? null
                                    : () => setState(() {
                                          _laudoFile = null;
                                          _fileName = null;
                                        }),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 40),

                      // -- Botão Finalizar (com loading inline) --
                      Theme(
                        data: Theme.of(context).copyWith(
                          elevatedButtonTheme: ElevatedButtonThemeData(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              disabledBackgroundColor: const Color(0xFFCBD5E1),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Finalizar Registo',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }
}
