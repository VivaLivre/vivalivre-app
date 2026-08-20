import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:viva_livre_app/core/theme/app_colors.dart';
import 'package:viva_livre_app/core/theme/theme_cubit.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';
import 'package:viva_livre_app/features/profile/data/repositories/profile_repository.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_text_field.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_primary_button.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = theme.colorScheme.onSurface;
    final iconColor = const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 32),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Configurações',
                  style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  color: iconColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // ── APARÊNCIA ──
            _SectionTitle(title: 'Aparência', isDark: isDark),
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return _SettingsMenuItem(
                  icon: Icons.palette_outlined,
                  title: 'Tema da Aplicação',
                  trailing: DropdownButton<ThemeMode>(
                    value: themeMode,
                    underline: const SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: iconColor),
                    style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('Automático')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Claro')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Escuro')),
                    ],
                    onChanged: (ThemeMode? newMode) {
                      if (newMode != null) {
                        context.read<ThemeCubit>().setTheme(newMode);
                      }
                    },
                  ),
                  isDark: isDark,
                  onTap: () {},
                );
              }
            ),
            const SizedBox(height: 16),
            
            // ── SEGURANÇA ──
            _SectionTitle(title: 'Segurança', isDark: isDark),
            _SettingsMenuItem(
              icon: Icons.lock_outline_rounded,
              title: 'Alterar Palavra-passe',
              isDark: isDark,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const _ChangePasswordSheet(),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── INFORMAÇÕES ──
            _SectionTitle(title: 'Informações', isDark: isDark),
            _SettingsMenuItem(
              icon: Icons.shield_outlined,
              title: 'Privacidade e LGPD',
              isDark: isDark,
              onTap: () => _showPrivacyDialog(context),
            ),
            _SettingsMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Ajuda e Suporte',
              isDark: isDark,
              onTap: () => _showHelpSupportDialog(context),
            ),
            const SizedBox(height: 16),

            // ── CONTA ──
            _SectionTitle(title: 'Conta', isDark: isDark),
            _SettingsMenuItem(
              icon: Icons.logout_rounded,
              title: 'Terminar Sessão',
              isDestructive: true,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context); // close sheet
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: theme.cardColor,
          title: Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Privacidade e LGPD', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Segurança e controle dos seus dados',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                SizedBox(height: 12),
                Text(
                  'No VivaLivre, levamos a sério a Lei Geral de Proteção de Dados (LGPD). Todos os seus registros de saúde, sintomas e urgências são armazenados com criptografia ponta a ponta e nunca são compartilhados sem sua permissão explícita.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                SizedBox(height: 12),
                Text(
                  'Direitos do Usuário:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                SizedBox(height: 6),
                Text(
                  '• Revogação de consentimento a qualquer momento.\n• Acesso completo ao relatório exportável.\n• Exclusão total e definitiva dos dados ao remover sua conta.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendi', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: theme.cardColor,
          title: Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Ajuda e Suporte', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Estamos aqui para ajudar!',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              SizedBox(height: 12),
              Text(
                'Se você tiver dúvidas, sugestões ou problemas técnicos com o VivaLivre, entre em contato através de nossos canais oficiais:',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 18, color: AppColors.lightSubText),
                  SizedBox(width: 8),
                  Text('suporte@vivalivre.org', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 18, color: AppColors.lightSubText),
                  SizedBox(width: 8),
                  Text('0800 123 4567', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isDark;
  final Widget? trailing;

  const _SettingsMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : Theme.of(context).colorScheme.onSurface;
    final bg = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 15),
        ),
        trailing: trailing ?? (isDestructive ? null : const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  _ChangePasswordSheet (Moved from profile_page.dart)
// ═════════════════════════════════════════════════════════════════════════════

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'A nova palavra-passe e a confirmação não coincidem.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final profileRepo = RepositoryProvider.of<ProfileRepository>(context);
      await profileRepo.updatePassword(
        newPassword: _newPasswordController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Palavra-passe atualizada com sucesso!'), backgroundColor: AppColors.successText),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Erro ao atualizar a palavra-passe.';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map<String, dynamic> && data['error'] != null) {
            errorMsg = data['error'];
          }
        } else {
          errorMsg = e.toString();
        }
        setState(() => _errorMessage = errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = theme.colorScheme.onSurface;
    final iconColor = const Color(0xFF94A3B8);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Alterar Palavra-passe', style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  color: iconColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _newPasswordController,
              hintText: 'Nova palavra-passe',
              obscureText: _obscureNew,
              prefixIcon: Icon(Icons.lock_reset_outlined, color: iconColor),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: iconColor),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'A nova palavra-passe é obrigatória.';
                if (v.length < 6) return 'Deve ter no mínimo 6 caracteres.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirmar nova palavra-passe',
              obscureText: _obscureNew,
              prefixIcon: Icon(Icons.lock_reset_outlined, color: iconColor),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            CustomPrimaryButton(
              onPressed: _isLoading ? null : _submit,
              label: 'Guardar Palavra-passe',
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
