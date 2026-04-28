import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';

/// Modelo de dados responsável pela serialização/deserialização
/// entre a entidade de domínio [HealthEntry] e os documentos do Firestore.
///
/// Todos os casts usam o padrão seguro `as Tipo?` com fallback `??`
/// para evitar crashes de tipagem quando um campo estiver ausente.
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

  /// Deserializa um documento Firestore para [HealthEntryModel].
  /// Defensivo contra campos nulos ou ausentes.
  factory HealthEntryModel.fromFirestore(DocumentSnapshot doc) {
    // Cast seguro — se .data() retornar null, usamos mapa vazio.
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    // Firestore armazena timestamps como Timestamp; convertemos para DateTime.
    final ts = data['timestamp'];
    final DateTime timestamp = ts is Timestamp
        ? ts.toDate()
        : DateTime.now();

    // symptoms é Array<String> no Firestore; protegemos contra null e tipos errados.
    final rawSymptoms = data['symptoms'];
    final List<String> symptoms = rawSymptoms is List
        ? rawSymptoms.map((e) => e.toString()).toList()
        : [];

    return HealthEntryModel(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      symptoms: symptoms,
      severity: (data['severity'] as String?) ?? 'Leve',
      notes: (data['notes'] as String?) ?? '',
      timestamp: timestamp,
      type: (data['type'] as String?) ?? 'sintoma',
    );
  }

  /// Serializa a entidade para o formato de escrita do Firestore.
  /// O campo [timestamp] usa [FieldValue.serverTimestamp()] para
  /// garantir consistência de fuso horário no servidor.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'symptoms': symptoms,
      'severity': severity,
      'notes': notes,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
    };
  }
}
