import 'dart:io';

void fixFile(String path, bool isPage) {
  var content = File(path).readAsStringSync();
  
  if (isPage) {
    content = content.replaceAll("const _kBlue = Color(0xFF2563EB);\n", "");
  } else {
    content = content.replaceAll("const _kBlue = Color(0xFF2563EB);\n\n", "");
  }
  
  content = content.replaceAll("extension AddBathroomTheme on BuildContext {\n  bool get isDark => Theme.of(this).brightness == Brightness.dark;\n  Color get bg => isDark ? Theme.of(this).scaffoldBackgroundColor : const Color(0xFFF3F4F6);\n  Color get cardBg => isDark ? Theme.of(this).cardColor : const Color(0xFFF9FAFB);\n  Color get border => isDark ? Theme.of(this).dividerColor : const Color(0xFFE5E7EB);\n  Color get textDark => isDark ? Colors.white : const Color(0xFF111827);\n  Color get textGray => isDark ? Colors.white70 : const Color(0xFF9CA3AF);\n  Color get sheetBg => isDark ? Theme.of(this).cardColor : Colors.white;\n}\n", "");
  
  content = content.replaceAll("_kBlue", "kAddBathroomBlue");
  
  if (isPage) {
    content = content.replaceAll("import '../widgets/add_bathroom_schedule_widgets.dart';", "import '../widgets/add_bathroom_schedule_widgets.dart';\nimport '../widgets/add_bathroom_theme.dart';");
  } else {
    // Widgets already have flutter/material.dart, let's just insert it
    content = content.replaceAll("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'add_bathroom_theme.dart';");
  }
  
  File(path).writeAsStringSync(content);
}

void main() {
  fixFile('lib/features/map/presentation/pages/add_bathroom_page.dart', true);
  fixFile('lib/features/map/presentation/widgets/add_bathroom_form_widgets.dart', false);
  fixFile('lib/features/map/presentation/widgets/add_bathroom_schedule_widgets.dart', false);
}
