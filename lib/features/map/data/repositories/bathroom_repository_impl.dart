import 'package:latlong2/latlong.dart';
import 'package:viva_livre_app/features/map/data/models/bathroom_model.dart';
import 'package:viva_livre_app/features/map/domain/entities/bathroom.dart';
import 'package:viva_livre_app/features/map/domain/repositories/i_bathroom_repository.dart';

class BathroomRepositoryImpl implements IBathroomRepository {
  final Distance _distance = const Distance();

  static const List<Map<String, dynamic>> _kBathroomsDb = [
    {
      'id': 1,
      'name': 'Minha Casa',
      'lat': -23.66070438587852,
      'lng': -46.43089117960558,
      'rating': 5.0,
      'tags': ['Privado', 'Acessível'],
      'open': true,
    },
    {
      'id': 2,
      'name': 'Nagumo',
      'lat': -23.665294452821797,
      'lng': -46.43136054859557,
      'rating': 4.5,
      'tags': ['Comercial', 'Limpo'],
      'open': true,
    },
    {
      'id': 3,
      'name': 'Shopping Mauá',
      'lat': -23.664299865247912,
      'lng': -46.46064939262508,
      'rating': 4.8,
      'tags': ['Acessível', 'Público'],
      'open': true,
    },
    {
      'id': 4,
      'name': 'Casa da Camila',
      'lat': -23.666502436775666,
      'lng': -46.52222072078094,
      'rating': 5.0,
      'tags': ['Privado', 'Seguro'],
      'open': true,
    },
  ];

  @override
  Future<List<Bathroom>> getBathrooms() async {
    // Simula tempo de busca na base de dados
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _kBathroomsDb.map((map) => BathroomModel.fromMap(map)).toList();
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
