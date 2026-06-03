import 'package:dio/dio.dart';
import '../../domain/repositories/i_crowdsource_repository.dart';

class CrowdsourceRepositoryImpl implements ICrowdsourceRepository {
  final Dio dio;

  CrowdsourceRepositoryImpl({required this.dio});

  @override
  Future<void> submitReport(String bathroomId, String reason, String? description) async {
    try {
      final payload = {
        "reason": reason,
      };
      
      if (description != null && description.isNotEmpty) {
        payload["description"] = description;
      }

      await dio.post('/api/bathrooms/$bathroomId/report', data: payload);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> submitSuggestion(String bathroomId, Map<String, dynamic> suggestedUpdates) async {
    try {
      final payload = {
        "suggested_updates": suggestedUpdates,
      };

      await dio.post('/api/bathrooms/$bathroomId/suggest', data: payload);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map && data['error'] != null) {
          return Exception(data['error']);
        }
      }
      return Exception(e.message ?? 'Erro de conexão.');
    }
    return Exception(e.toString());
  }
}
