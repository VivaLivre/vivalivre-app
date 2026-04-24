import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'dart:math' as math;

class HealthRepository {
  // Mock data, replace with actual data source later
  final List<HealthEntry> _mockEntries = [
    HealthEntry(
      id: '1',
      date: DateTime.now().subtract(const Duration(days: 1)),
      symptoms: 'Dor de cabeça, náusea',
      severity: 'Moderada',
      notes: 'Senti mais durante a tarde.',
    ),
    HealthEntry(
      id: '2',
      date: DateTime.now().subtract(const Duration(days: 3)),
      symptoms: 'Fadiga, dor abdominal',
      severity: 'Leve',
      notes: 'Melhorou após repouso.',
    ),
  ];

  Future<List<HealthEntry>> getHealthEntries() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // Return a copy to prevent external modification
    return List.from(_mockEntries);
  }

  Future<void> addHealthEntry(HealthEntry entry) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // Add the new entry to the mock list
    _mockEntries.add(
      entry.copyWith(id: math.Random().nextInt(10000).toString()),
    );
  }
}

// Extension to enable copyWith for HealthEntry
extension HealthEntryCopyWith on HealthEntry {
  HealthEntry copyWith({
    String? id,
    DateTime? date,
    String? symptoms,
    String? severity,
    String? notes,
  }) {
    return HealthEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      symptoms: symptoms ?? this.symptoms,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
    );
  }
}
