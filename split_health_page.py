import re

def process():
    with open('lib/features/health/presentation/pages/health_page.dart', 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    def write_widget(filename, start, end, class_names, imports):
        content = imports + '\n' + ''.join(lines[start-1:end])
        for old, new in class_names.items():
            content = content.replace(old, new)
        with open('lib/features/health/presentation/widgets/' + filename, 'w', encoding='utf-8') as f:
            f.write(content)
            
    # Extract
    write_widget('empty_timeline.dart', 416, 468, {'_EmptyTimeline': 'EmptyTimeline'}, "import 'package:flutter/material.dart';")
    
    write_widget('timeline_item.dart', 469, 749, {'_TimelineItem': 'TimelineItem', '_EntryDetailDialog': 'EntryDetailDialog'}, "import 'package:flutter/material.dart';\nimport 'package:intl/intl.dart';\nimport 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';\nimport 'entry_detail_dialog.dart';")
    
    write_widget('entry_detail_dialog.dart', 750, 1079, {'_EntryDetailDialog': 'EntryDetailDialog', '_DetailSection': 'DetailSection'}, "import 'package:flutter/material.dart';\nimport 'package:intl/intl.dart';\nimport 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';")
    
    write_widget('symptom_search_modal.dart', 1080, 1318, {'_SymptomSearchModal': 'SymptomSearchModal', '_SymptomSearchModalState': '_SymptomSearchModalState'}, "import 'package:flutter/material.dart';")
    
    write_widget('bathroom_extras_modal.dart', 1319, 1502, {'_BathroomExtrasModal': 'BathroomExtrasModal', '_BathroomExtrasModalState': '_BathroomExtrasModalState'}, "import 'package:flutter/material.dart';")
    
    # Update health_page.dart
    remaining = lines[:415]
    updated_main = ''.join(remaining)
    updated_main = updated_main.replace('_EmptyTimeline', 'EmptyTimeline')
    updated_main = updated_main.replace('_TimelineItem', 'TimelineItem')
    updated_main = updated_main.replace('_SymptomSearchModal', 'SymptomSearchModal')
    updated_main = updated_main.replace('_BathroomExtrasModal', 'BathroomExtrasModal')
    
    # Insert imports in health_page
    import_idx = 0
    for i, line in enumerate(remaining):
        if line.startswith('import '):
            import_idx = i
            
    imports_to_add = [
        "import '../widgets/empty_timeline.dart';",
        "import '../widgets/timeline_item.dart';",
        "import '../widgets/symptom_search_modal.dart';",
        "import '../widgets/bathroom_extras_modal.dart';"
    ]
    
    remaining.insert(import_idx + 1, '\n'.join(imports_to_add) + '\n')
    
    updated_main = ''.join(remaining)
    updated_main = updated_main.replace('_EmptyTimeline', 'EmptyTimeline')
    updated_main = updated_main.replace('_TimelineItem', 'TimelineItem')
    updated_main = updated_main.replace('_SymptomSearchModal', 'SymptomSearchModal')
    updated_main = updated_main.replace('_BathroomExtrasModal', 'BathroomExtrasModal')
    
    with open('lib/features/health/presentation/pages/health_page.dart', 'w', encoding='utf-8') as f:
        f.write(updated_main)

process()
