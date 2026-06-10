import 'package:flutter/material.dart';
import 'package:viva_livre_app/core/theme/app_colors.dart';

/// Botão Google padronizado para uso em Login e Cadastro.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Continuar com o Google',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone colorido do Google simulado com letras G coloridas
          _GoogleLogo(),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Fundo circular branco
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Divisor com texto "Ou continue com"
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.darkDivider : Colors.grey.shade300;
    final textColor = isDark ? Colors.white54 : Colors.grey.shade500;

    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Ou continue com',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
      ],
    );
  }
}

/// Label de campo de texto padronizado
class FieldLabel extends StatelessWidget {
  final String text;

  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : const Color(0xFF334155);

    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}
