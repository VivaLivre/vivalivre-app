import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/pages/add_bathroom_page.dart');
  final lines = file.readAsLinesSync();
  
  void writeWidget(String filename, int start, int end, Map<String, String> replacements, String imports) {
    int endIdx = end > lines.length ? lines.length : end;
    var content = imports + '\n' + lines.sublist(start - 1, endIdx).join('\n');
    replacements.forEach((old, newStr) {
      content = content.replaceAll(old, newStr);
    });
    File('lib/features/map/presentation/widgets/' + filename).writeAsStringSync(content);
  }
  
  // UI widgets: 828 to 1099
  // 828 class _CircleButton
  // 858 class _SectionLabel
  // 883 class _ToggleRow
  // 921 class _PhotoPicker
  // 1057 class _PhotoOptionTile
  writeWidget('add_bathroom_form_widgets.dart', 828, 1099, {
    '_CircleButton': 'CircleButton',
    '_SectionLabel': 'SectionLabel',
    '_ToggleRow': 'ToggleRow',
    '_PhotoPicker': 'PhotoPicker',
    '_PhotoOptionTile': 'PhotoOptionTile'
  }, "import 'dart:io';\nimport 'package:flutter/material.dart';\nimport 'package:flutter/foundation.dart' show kIsWeb;\nimport 'package:image_picker/image_picker.dart';\n");
  
  // Schedule widgets: 1100 to 1342
  // 1100 class _OperatingHoursChip
  // 1152 class _CustomScheduleWidget
  // 1197 class _DayRow
  // 1305 class _TimeButton
  writeWidget('add_bathroom_schedule_widgets.dart', 1100, lines.length, {
    '_OperatingHoursChip': 'OperatingHoursChip',
    '_CustomScheduleWidget': 'CustomScheduleWidget',
    '_DayRow': 'DayRow',
    '_TimeButton': 'TimeButton'
  }, "import 'package:flutter/material.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:viva_livre_app/features/map/presentation/bloc/add_bathroom_bloc.dart';\n");
  
  var remaining = lines.sublist(0, 827);
  
  int importIdx = 0;
  for (int i = 0; i < remaining.length; i++) {
    if (remaining[i].startsWith('import ')) {
      importIdx = i;
    }
  }
  
  final importsToAdd = [
    "import '../widgets/add_bathroom_form_widgets.dart';",
    "import '../widgets/add_bathroom_schedule_widgets.dart';"
  ];
  
  remaining.insertAll(importIdx + 1, importsToAdd);
  
  var updatedMain = remaining.join('\n');
  updatedMain = updatedMain.replaceAll('_CircleButton', 'CircleButton');
  updatedMain = updatedMain.replaceAll('_SectionLabel', 'SectionLabel');
  updatedMain = updatedMain.replaceAll('_ToggleRow', 'ToggleRow');
  updatedMain = updatedMain.replaceAll('_PhotoPicker', 'PhotoPicker');
  updatedMain = updatedMain.replaceAll('_PhotoOptionTile', 'PhotoOptionTile');
  updatedMain = updatedMain.replaceAll('_OperatingHoursChip', 'OperatingHoursChip');
  updatedMain = updatedMain.replaceAll('_CustomScheduleWidget', 'CustomScheduleWidget');
  updatedMain = updatedMain.replaceAll('_DayRow', 'DayRow');
  updatedMain = updatedMain.replaceAll('_TimeButton', 'TimeButton');
  
  file.writeAsStringSync(updatedMain);
}
