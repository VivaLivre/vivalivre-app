import 'dart:io';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:viva_livre_app/features/map/data/models/bathroom_model.dart';
import 'package:viva_livre_app/features/map/domain/entities/bathroom.dart';
import 'package:viva_livre_app/features/map/domain/repositories/i_bathroom_repository.dart';
import 'package:viva_livre_app/core/api/api_client.dart';

class BathroomRepositoryImpl implements IBathroomRepository {
  final ApiClient _apiClient;
  final Distance _distance = const Distance();

  BathroomRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<Bathroom>> getBathrooms(double lat, double lng, {double radius = 5000}) async {
    try {
      final response = await _apiClient.dio.get('/api/bathrooms/nearby', queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
      });

      if (response.statusCode == 200) {
        // If the API returns a list of bathrooms
        if (response.data is List) {
          return (response.data as List).map((map) => BathroomModel.fromMap(map)).toList();
        }
      }
    } catch (e) {
      // Fallback to empty list or handle error
    }
    return [];
  }

  @override
  Bathroom? findNearestBathroom(LatLng currentPosition, List<Bathroom> bathrooms) {
    if (bathrooms.isEmpty) return null;

    Bathroom? nearest;
    double nearestMeters = double.infinity;

    for (final bathroom in bathrooms) {
      final meters = _distance.as(
        LengthUnit.Meter,
        currentPosition,
        bathroom.location,
      );
      
      if (meters < nearestMeters) {
        nearestMeters = meters;
        nearest = bathroom;
      }
    }

    return nearest;
  }

  @override
  double calculateDistance(LatLng from, LatLng to) {
    return _distance.as(LengthUnit.Meter, from, to);
  }

  @override
  Future<void> addBathroomRequest({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required bool isAccessible,
    required bool hasChangingTable,
    required bool isFree,
    String? comment,
    required File photo,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'address': address,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'is_accessible': isAccessible.toString(),
      'has_changing_table': hasChangingTable.toString(),
      'is_free': isFree.toString(),
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'photo': await MultipartFile.fromFile(
        photo.path,
        filename: photo.path.split(Platform.pathSeparator).last,
      ),
    });

    final response = await _apiClient.dio.post(
      '/api/bathrooms/request',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    if (response.statusCode != 201) {
      throw Exception(response.data?['error'] ?? 'Erro ao enviar sugestão.');
    }
  }
}
