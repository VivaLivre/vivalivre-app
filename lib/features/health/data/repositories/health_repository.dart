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
        'symptoms': entry.symptoms,
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
  Future<List<HealthEntry>> getEntries(String userId, {String? filterDate}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/health/entries',
        queryParameters: filterDate != null ? {'date': filterDate} : null,
      );
      if (response.statusCode == 200 && response.data is List) {
        debugPrint('[HealthRepository] getEntries: sucesso');
        return (response.data as List).map((json) => HealthEntryModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HealthRepository] getEntries ERROR: $e');
    }
    return [];
  }
}
