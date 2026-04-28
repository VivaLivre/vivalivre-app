import 'package:latlong2/latlong.dart';
import 'package:viva_livre_app/features/map/domain/entities/bathroom.dart';

class BathroomModel extends Bathroom {
  const BathroomModel({
    required super.id,
    required super.name,
    required super.location,
    required super.rating,
    required super.tags,
    required super.isOpen,
  });

  factory BathroomModel.fromMap(Map<String, dynamic> map) {
    return BathroomModel(
      id: map['id'] as int,
      name: map['name'] as String,
      location: LatLng(map['lat'] as double, map['lng'] as double),
      rating: (map['rating'] as num).toDouble(),
      tags: List<String>.from(map['tags'] as List),
      isOpen: map['open'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lat': location.latitude,
      'lng': location.longitude,
      'rating': rating,
      'tags': tags,
      'open': isOpen,
    };
  }
}
