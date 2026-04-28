import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:viva_livre_app/features/health/data/models/health_entry_model.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/domain/repositories/i_health_repository.dart';

/// Implementação concreta de [IHealthRepository] usando Cloud Firestore.
///
/// Estrutura da coleção:
///   users/{userId}/health_records/{docId}
///
/// Usar subcoleção garante isolamento por utilizador e simplifica
/// as regras de segurança do Firestore.
class HealthRepositoryImpl implements IHealthRepository {
  final FirebaseFirestore _firestore;

  HealthRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referência base para os registos de um utilizador específico.
  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('health_records');

  @override
  Future<void> addEntry(HealthEntry entry) async {
    // Garante que o entry tem um userId válido antes de escrever.
    if (entry.userId.isEmpty) {
      throw Exception('userId não pode estar vazio ao gravar um registo de saúde.');
    }

    final model = HealthEntryModel(
      id: '', // Ignorado — Firestore gera o ID automaticamente com .add()
      userId: entry.userId,
      symptoms: entry.symptoms,
      severity: entry.severity,
      notes: entry.notes,
      timestamp: entry.timestamp,
      type: entry.type,
    );

    await _collection(entry.userId).add(model.toFirestore());
  }

  @override
  Stream<List<HealthEntry>> watchEntries(String userId) {
    if (userId.isEmpty) {
      // Utilizador não autenticado — Stream vazio e seguro.
      return const Stream.empty();
    }

    return _collection(userId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      // Defensivo: documentos com erro de deserialização são ignorados
      // em vez de derrubar o Stream inteiro.
      final entries = <HealthEntry>[];
      for (final doc in snapshot.docs) {
        try {
          entries.add(HealthEntryModel.fromFirestore(doc));
        } catch (_) {
          // Documento malformado — ignorar e continuar.
        }
      }
      return entries;
    });
  }
}
