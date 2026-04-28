import 'package:equatable/equatable.dart';

/// Entidade de domínio para um registo clínico do utilizador.
///
/// Regras de negócio:
/// - [symptoms] é uma lista estruturada (nunca String concatenada).
/// - [userId] garante isolamento multi-utilizador no Firestore.
/// - [timestamp] é gerado pelo servidor (FieldValue.serverTimestamp) na camada de dados.
/// - [type] distingue eventos de banheiro de sintomas para o dashboard.
class HealthEntry extends Equatable {
  final String id;
  final String userId;
  final List<String> symptoms;
  final String severity;
  final String notes;
  final DateTime timestamp;
  final String type; // 'banheiro' | 'sintoma'

  const HealthEntry({
    required this.id,
    required this.userId,
    required this.symptoms,
    required this.severity,
    required this.notes,
    required this.timestamp,
    required this.type,
  });

  HealthEntry copyWith({
    String? id,
    String? userId,
    List<String>? symptoms,
    String? severity,
    String? notes,
    DateTime? timestamp,
    String? type,
  }) {
    return HealthEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symptoms: symptoms ?? this.symptoms,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [id, userId, symptoms, severity, notes, timestamp, type];
}
