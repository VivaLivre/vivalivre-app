import 'dart:io';

void main() {
  final file = File('lib/features/health/presentation/pages/health_page.dart');
  final lines = file.readAsLinesSync();
  
  void writeWidget(String filename, int start, int end, Map<String, String> replacements, String imports) {
    int endIdx = end > lines.length ? lines.length : end;
    var content = imports + '\n' + lines.sublist(start - 1, endIdx).join('\n');
    replacements.forEach((old, newStr) {
      content = content.replaceAll(old, newStr);
    });
    File('lib/features/health/presentation/widgets/' + filename).writeAsStringSync(content);
  }
  
  writeWidget('empty_timeline.dart', 416, 468, {'_EmptyTimeline': 'EmptyTimeline'}, "import 'package:flutter/material.dart';\n");
  
  writeWidget('timeline_item.dart', 469, 749, {'_TimelineItem': 'TimelineItem', '_EntryDetailDialog': 'EntryDetailDialog'}, "import 'package:flutter/material.dart';\nimport 'package:intl/intl.dart';\nimport 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';\nimport 'entry_detail_dialog.dart';\n");
  
  writeWidget('entry_detail_dialog.dart', 750, 1079, {'_EntryDetailDialog': 'EntryDetailDialog', '_DetailSection': 'DetailSection'}, "import 'package:flutter/material.dart';\nimport 'package:intl/intl.dart';\nimport 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';\n");
  
  writeWidget('symptom_search_modal.dart', 1080, 1318, {'_SymptomSearchModal': 'SymptomSearchModal', '_SymptomSearchModalState': 'SymptomSearchModalState'}, "import 'package:flutter/material.dart';\n");
  
  writeWidget('bathroom_extras_modal.dart', 1319, 1502, {'_BathroomExtrasModal': 'BathroomExtrasModal', '_BathroomExtrasModalState': 'BathroomExtrasModalState'}, "import 'package:flutter/material.dart';\n");
  
  var remaining = lines.sublist(0, 415);
  
  int importIdx = 0;
  for (int i = 0; i < remaining.length; i++) {
    if (remaining[i].startsWith('import ')) {
      importIdx = i;
    }
  }
  
  final importsToAdd = [
    "import '../widgets/empty_timeline.dart';",
    "import '../widgets/timeline_item.dart';",
    "import '../widgets/symptom_search_modal.dart';",
    "import '../widgets/bathroom_extras_modal.dart';"
  ];
  
  remaining.insertAll(importIdx + 1, importsToAdd);
  
  var updatedMain = remaining.join('\n');
  updatedMain = updatedMain.replaceAll('_EmptyTimeline', 'EmptyTimeline');
  updatedMain = updatedMain.replaceAll('_TimelineItem', 'TimelineItem');
  updatedMain = updatedMain.replaceAll('_SymptomSearchModal', 'SymptomSearchModal');
  updatedMain = updatedMain.replaceAll('_BathroomExtrasModal', 'BathroomExtrasModal');
  
  file.writeAsStringSync(updatedMain);
}
