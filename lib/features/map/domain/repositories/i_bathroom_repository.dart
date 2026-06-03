import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:viva_livre_app/features/map/domain/entities/bathroom.dart';

abstract class IBathroomRepository {
  Future<List<Bathroom>> getBathrooms(double lat, double lng, {double radius = 5000});
  Bathroom? findNearestBathroom(LatLng currentPosition, List<Bathroom> bathrooms);
  double calculateDistance(LatLng from, LatLng to);

  /// Submits a bathroom suggestion with photo for admin approval.
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
  });
}
