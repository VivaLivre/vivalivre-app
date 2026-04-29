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
  Future<List<Bathroom>> getBathrooms() async {
    try {
      // For now, we use a fixed radius or get it from parameters
      final response = await _apiClient.dio.get('/api/bathrooms/nearby', queryParameters: {
        'lat': -23.66, // Placeholder, usually passed from UI
        'lng': -46.43,
        'radius': 5000,
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
}
