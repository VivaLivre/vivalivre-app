import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/bathroom_card.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll("import 'package:viva_livre_app/features/ratings/presentation/bloc/rating_bloc.dart';\n", '');
  file.writeAsStringSync(content);
}
