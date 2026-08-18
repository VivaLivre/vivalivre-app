import 'package:flutter/material.dart';

const kAddBathroomBlue = Color(0xFF2563EB);

extension AddBathroomTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? Theme.of(this).scaffoldBackgroundColor : const Color(0xFFF3F4F6);
  Color get cardBg => isDark ? Theme.of(this).cardColor : const Color(0xFFF9FAFB);
  Color get border => isDark ? Theme.of(this).dividerColor : const Color(0xFFE5E7EB);
  Color get textDark => isDark ? Colors.white : const Color(0xFF111827);
  Color get textGray => isDark ? Colors.white70 : const Color(0xFF9CA3AF);
  Color get sheetBg => isDark ? Theme.of(this).cardColor : Colors.white;
}
