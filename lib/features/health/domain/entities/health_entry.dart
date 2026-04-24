import 'package:equatable/equatable.dart';

class HealthEntry extends Equatable {
  final String id;
  final DateTime date;
  final String symptoms;
  final String severity;
  final String notes;

  const HealthEntry({
    required this.id,
    required this.date,
    required this.symptoms,
    required this.severity,
    required this.notes,
  });

  @override
  List<Object?> get props => [id, date, symptoms, severity, notes];
}
