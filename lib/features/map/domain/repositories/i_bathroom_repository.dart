import 'package:latlong2/latlong.dart';
import 'package:viva_livre_app/features/map/domain/entities/bathroom.dart';

abstract class IBathroomRepository {
  Future<List<Bathroom>> getBathrooms();
  Bathroom? findNearestBathroom(LatLng currentPosition, List<Bathroom> bathrooms);
  double calculateDistance(LatLng from, LatLng to);
}
