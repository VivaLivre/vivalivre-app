import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';

/// Modelo de dados responsável pela serialização/deserialização
/// entre a entidade de domínio [HealthEntry] e a API REST.
class HealthEntryModel extends HealthEntry {
  const HealthEntryModel({
    required super.id,
    required super.userId,
    required super.symptoms,
    required super.severity,
    required super.notes,
    required super.timestamp,
    required super.type,
  });

  factory HealthEntryModel.fromJson(Map<String, dynamic> json) {
    return HealthEntryModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      symptoms: (json['symptoms'] as List?)?.map((e) => e.toString()).toList() ?? [],
      severity: json['severity'] ?? 'Leve',
      notes: json['description'] ?? json['notes'] ?? '',
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : (json['entry_date'] != null ? DateTime.parse(json['entry_date']) : DateTime.now()),
      type: json['type'] ?? 'sintoma',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'symptoms': symptoms,
      'severity': severity,
      'description': notes,
      'type': type,
    };
  }
}
