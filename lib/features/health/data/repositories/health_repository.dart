import 'package:flutter/foundation.dart';
import 'package:viva_livre_app/features/health/data/models/health_entry_model.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/features/health/domain/repositories/i_health_repository.dart';
import 'package:viva_livre_app/core/api/api_client.dart';

class HealthRepositoryImpl implements IHealthRepository {
  final ApiClient _apiClient;

  HealthRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<void> addEntry(HealthEntry entry) async {
    try {
      await _apiClient.dio.post('/api/health/entries', data: {
        'type': entry.type,
        'description': entry.notes,
        'severity': entry.severity,
      });
      debugPrint('[HealthRepository] addEntry: sucesso');
    } catch (e) {
      debugPrint('[HealthRepository] addEntry ERROR: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteEntry(String docId, String userId) async {
    try {
      await _apiClient.dio.delete('/api/health/entries/$docId');
    } catch (e) {
      debugPrint('[HealthRepository] deleteEntry ERROR: $e');
      rethrow;
    }
  }

  @override
  Stream<List<HealthEntry>> watchEntries(String userId) {
    // Since we don't have a WebSocket/Stream backend yet, we'll simulate a stream
    // by fetching once. In a real app, you'd use a polling mechanism or WebSockets.
    return Stream.fromFuture(_fetchEntries());
  }

  Future<List<HealthEntry>> _fetchEntries() async {
    try {
      final response = await _apiClient.dio.get('/api/health/entries');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((json) => HealthEntryModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HealthRepository] _fetchEntries ERROR: $e');
    }
    return [];
  }
}
