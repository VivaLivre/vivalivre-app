import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:viva_livre_app/core/network/retry_helper.dart';
import 'package:viva_livre_app/features/health/data/models/health_entry_model.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/domain/repositories/i_health_repository.dart';

/// Implementação concreta de [IHealthRepository] usando Cloud Firestore.
///
/// Estrutura da coleção (raiz):
///   health_records/{docId}
///     - userId: String  ← campo dentro do documento para filtragem
///
/// Esta estrutura bate diretamente com as regras de segurança do Firebase:
///   match /health_records/{doc} {
///     allow read, write: if request.auth.uid == resource.data.userId;
///   }
class HealthRepositoryImpl implements IHealthRepository {
  final FirebaseFirestore _firestore;

  HealthRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referência à coleção raiz — alinhada com as regras de segurança do Firebase.
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('health_records');

  @override
  Future<void> addEntry(HealthEntry entry) async {
    if (entry.userId.isEmpty) {
      throw Exception('userId não pode estar vazio ao gravar um registo de saúde.');
    }

    try {
      final model = HealthEntryModel(
        id: '', // Firestore gera o ID via .add()
        userId: entry.userId,
        symptoms: entry.symptoms,
        severity: entry.severity,
        notes: entry.notes,
        timestamp: entry.timestamp,
        type: entry.type,
      );

      // O campo userId é gravado DENTRO do documento para permitir
      // a query por utilizador e as regras de segurança Firestore.
      await retryOperation<void>(
        operation: () async {
          await _collection.add(model.toFirestore());
        },
      );

      debugPrint('[HealthRepository] addEntry: sucesso para userId=${entry.userId}');
    } catch (e) {
      // Captura PERMISSION_DENIED, falhas de rede e outros erros silenciosos.
      debugPrint('[HealthRepository] addEntry ERROR: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteEntry(String docId, String userId) async {
    if (docId.isEmpty || userId.isEmpty) {
      throw Exception('docId e userId são obrigatórios para eliminar um registo.');
    }

    try {
      await _collection.doc(docId).delete();
      debugPrint('[HealthRepository] deleteEntry: doc $docId eliminado.');
    } catch (e) {
      debugPrint('[HealthRepository] deleteEntry ERROR: $e');
      rethrow;
    }
  }

  @override
  Stream<List<HealthEntry>> watchEntries(String userId) {
    if (userId.isEmpty) {
      debugPrint('[HealthRepository] watchEntries: userId vazio — Stream encerrado.');
      return const Stream.empty();
    }

    try {
      return _collection
          .where('userId', isEqualTo: userId) // filtra por utilizador logado
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .map((snapshot) {
        debugPrint('[HealthRepository] watchEntries: ${snapshot.docs.length} registos recebidos.');

        final entries = <HealthEntry>[];
        for (final doc in snapshot.docs) {
          try {
            entries.add(HealthEntryModel.fromFirestore(doc));
          } catch (e) {
            // Documento malformado — ignorado para não derrubar o Stream.
            debugPrint('[HealthRepository] fromFirestore ERROR (doc ${doc.id}): $e');
          }
        }
        return entries;
      });
    } catch (e) {
      debugPrint('[HealthRepository] watchEntries setup ERROR: $e');
      return const Stream.empty();
    }
  }
}
