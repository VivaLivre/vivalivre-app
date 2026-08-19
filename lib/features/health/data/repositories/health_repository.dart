import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:viva_livre_app/features/health/data/models/health_entry_model.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/domain/repositories/i_health_repository.dart';
import 'package:viva_livre_app/core/api/api_client.dart';
import 'package:viva_livre_app/core/database/local_database.dart';

class HealthRepositoryImpl implements IHealthRepository {
  final ApiClient _apiClient;
  final _uuid = const Uuid();

  HealthRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> syncPendingEntries() async {
    final db = await LocalDatabase.instance.database;
    
    // Obter registos pendentes de inserção (sync_status = 1)
    final pendingAdds = await db.query('health_entries', where: 'sync_status = ?', whereArgs: [1]);
    for (var map in pendingAdds) {
      try {
        final symptoms = (jsonDecode(map['symptoms'] as String) as List).cast<String>();
        final response = await _apiClient.dio.post('/api/health/entries', data: {
          'type': map['type'],
          'description': map['description'],
          'severity': map['severity'],
          'symptoms': symptoms,
          // Idealmente, deveríamos enviar o 'date' original, mas a API atual não suporta
        });
        
        final remoteId = response.data['id'].toString();
        await db.update(
          'health_entries',
          {'sync_status': 0, 'remote_id': remoteId},
          where: 'local_id = ?',
          whereArgs: [map['local_id']],
        );
      } catch (e) {
        debugPrint('[HealthRepository] sync pending add ERROR: $e');
      }
    }

    // Obter registos pendentes de eliminação (sync_status = 2)
    final pendingDeletes = await db.query('health_entries', where: 'sync_status = ?', whereArgs: [2]);
    for (var map in pendingDeletes) {
      final remoteId = map['remote_id'] as String?;
      if (remoteId != null && remoteId.isNotEmpty) {
        try {
          await _apiClient.dio.delete('/api/health/entries/$remoteId');
          await db.delete('health_entries', where: 'local_id = ?', whereArgs: [map['local_id']]);
        } catch (e) {
          debugPrint('[HealthRepository] sync pending delete ERROR: $e');
        }
      } else {
        // Se por algum motivo não tiver remote_id, apenas apagamos localmente
        await db.delete('health_entries', where: 'local_id = ?', whereArgs: [map['local_id']]);
      }
    }
  }

  @override
  Future<HealthEntry> addEntry(HealthEntry entry) async {
    final db = await LocalDatabase.instance.database;
    final localId = _uuid.v4();
    final nowStr = entry.timestamp.toIso8601String();

    // 1. Guardar localmente como Pendente (sync_status = 1)
    await db.insert('health_entries', {
      'local_id': localId,
      'remote_id': null,
      'user_id': entry.userId,
      'type': entry.type,
      'description': entry.notes,
      'severity': entry.severity,
      'symptoms': jsonEncode(entry.symptoms),
      'date': nowStr,
      'sync_status': 1,
    });

    final newModel = HealthEntryModel(
      id: localId, // Usamos localId temporariamente
      userId: entry.userId,
      symptoms: entry.symptoms,
      severity: entry.severity,
      notes: entry.notes,
      timestamp: entry.timestamp,
      type: entry.type,
      localId: localId,
      syncStatus: 1,
    );

    // 2. Tentar sincronizar silenciosamente
    syncPendingEntries();

    return newModel;
  }

  @override
  Future<void> deleteEntry(String id) async {
    final db = await LocalDatabase.instance.database;

    // Verificar se o ID passado é um local_id ou remote_id
    final result = await db.query('health_entries', where: 'local_id = ? OR remote_id = ?', whereArgs: [id, id]);
    
    if (result.isNotEmpty) {
      final map = result.first;
      final localId = map['local_id'] as String;
      final remoteId = map['remote_id'] as String?;

      if (remoteId == null || remoteId.isEmpty) {
        // Ainda não foi sincronizado, apagar apenas localmente
        await db.delete('health_entries', where: 'local_id = ?', whereArgs: [localId]);
      } else {
        // Marcar como pendente de eliminação (sync_status = 2)
        await db.update('health_entries', {'sync_status': 2}, where: 'local_id = ?', whereArgs: [localId]);
      }
    } else {
      // Se não existir localmente mas foi passado, tenta direto na API (edge case)
      try {
        await _apiClient.dio.delete('/api/health/entries/$id');
      } catch (e) {
        debugPrint('[HealthRepository] fallback delete ERROR: $e');
        rethrow; // Não conseguimos gerir isto offline
      }
    }

    // Tentar sincronizar silenciosamente
    syncPendingEntries();
  }

  @override
  Future<List<HealthEntry>> getEntries({String? filterDate}) async {
    final db = await LocalDatabase.instance.database;

    // 1. Tentar fazer sync de pendentes primeiro e buscar novidades
    try {
      await syncPendingEntries();
      
      final response = await _apiClient.dio.get(
        '/api/health/entries',
        queryParameters: filterDate != null ? {'date': filterDate} : null,
      );
      
      if (response.statusCode == 200 && response.data is List) {
        // Para cada registo remoto, fazer upsert na DB local (com sync_status = 0)
        for (var json in response.data) {
          final remoteId = json['id'].toString();
          final type = json['type'] ?? 'sintoma';
          final desc = json['description'] ?? json['notes'] ?? '';
          final sev = json['severity'] ?? 'Leve';
          final symps = jsonEncode((json['symptoms'] as List?)?.map((e) => e.toString()).toList() ?? []);
          final dateStr = json['created_at'] ?? json['entry_date'] ?? DateTime.now().toIso8601String();
          final userId = json['user_id']?.toString() ?? '';

          // Verificar se já existe pelo remote_id
          final existing = await db.query('health_entries', where: 'remote_id = ?', whereArgs: [remoteId]);
          if (existing.isEmpty) {
             await db.insert('health_entries', {
               'local_id': _uuid.v4(),
               'remote_id': remoteId,
               'user_id': userId,
               'type': type,
               'description': desc,
               'severity': sev,
               'symptoms': symps,
               'date': dateStr,
               'sync_status': 0,
             });
          } else {
             await db.update('health_entries', {
               'type': type,
               'description': desc,
               'severity': sev,
               'symptoms': symps,
               'date': dateStr,
               'sync_status': 0, // Garante que está synced
             }, where: 'remote_id = ?', whereArgs: [remoteId]);
          }
        }
      }
    } catch (e) {
      debugPrint('[HealthRepository] getEntries API/Sync ERROR (offline fallback): $e');
    }

    // 2. Retornar tudo o que está na DB local (que não seja Pendente Eliminação)
    // Se tiver filterDate, precisamos de filtrar. A base de dados guarda a string ISO completa.
    // Filtragem local usando string 'LIKE' ou processando na memória.
    
    final localData = await db.query('health_entries', where: 'sync_status != ?', whereArgs: [2], orderBy: 'date DESC');
    
    List<HealthEntry> entries = localData.map((map) {
      return HealthEntryModel(
        id: (map['remote_id'] as String?)?.isNotEmpty == true ? map['remote_id'] as String : map['local_id'] as String,
        userId: map['user_id'] as String,
        type: map['type'] as String,
        notes: map['description'] as String? ?? '',
        severity: map['severity'] as String,
        symptoms: (jsonDecode(map['symptoms'] as String) as List).cast<String>(),
        timestamp: DateTime.parse(map['date'] as String).toLocal(),
        localId: map['local_id'] as String,
        syncStatus: map['sync_status'] as int,
      );
    }).toList();

    // Filtro local na memória caso tenha filterDate (ex: 'today' ou formato YYYY-MM-DD)
    if (filterDate != null) {
      final now = DateTime.now();
      entries = entries.where((e) {
        if (filterDate == 'today') {
           return e.timestamp.year == now.year && e.timestamp.month == now.month && e.timestamp.day == now.day;
        } else {
           // Assume formato yyyy-MM-dd
           final reqDate = DateTime.tryParse(filterDate);
           if (reqDate == null) return true;
           return e.timestamp.year == reqDate.year && e.timestamp.month == reqDate.month && e.timestamp.day == reqDate.day;
        }
      }).toList();
    }

    return entries;
  }
}
