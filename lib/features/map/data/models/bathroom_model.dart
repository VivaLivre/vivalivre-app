import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:viva_livre_app/features/map/domain/entities/bathroom.dart';

class BathroomModel extends Bathroom {
  const BathroomModel({
    required super.id,
    required super.name,
    required super.location,
    required super.rating,
    required super.tags,
    super.address,
    super.isAccessible,
    super.hasChangingTable,
    super.isFree,
    super.cleanlinessRating,
    super.accessibilityRating,
    super.photoUrl,
    super.operatingHours,
    super.observations,
  });

  factory BathroomModel.fromMap(Map<String, dynamic> map) {
    final latitude =
        (map['latitude'] as num?)?.toDouble() ??
        (map['lat'] as num?)?.toDouble() ??
        0.0;
    final longitude =
        (map['longitude'] as num?)?.toDouble() ??
        (map['lng'] as num?)?.toDouble() ??
        0.0;
    final isAccessible = (map['is_accessible'] as bool?) ?? false;

    // Parse operating_hours — can be a Map, a JSON string, or null
    Map<String, dynamic> operatingHours = const {'type': 'unknown'};
    final rawHours = map['operating_hours'];
    if (rawHours is Map<String, dynamic>) {
      operatingHours = rawHours;
    } else if (rawHours is String && rawHours.isNotEmpty) {
      try {
        operatingHours = json.decode(rawHours) as Map<String, dynamic>;
      } catch (_) {
        // Keep default
      }
    }

    return BathroomModel(
      id: (map['id'] as int?) ?? 0,
      name: (map['name'] as String?) ?? 'Sem nome',
      location: LatLng(latitude, longitude),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      tags:
          (map['tags'] as List?)?.map((e) => e.toString()).toList() ??
          [if (isAccessible) 'Acessivel'],
      address: (map['address'] as String?),
      isAccessible: isAccessible,
      hasChangingTable: (map['has_changing_table'] as bool?) ?? false,
      isFree: (map['is_free'] as bool?) ?? false,
      cleanlinessRating: (map['cleanliness_rating'] as num?)?.toDouble() ?? 0.0,
      accessibilityRating: (map['accessibility_rating'] as num?)?.toDouble() ?? 0.0,
      photoUrl: (map['photo_url'] as String?),
      operatingHours: operatingHours,
      observations: (map['observations'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'lat': location.latitude,
      'lng': location.longitude,
      'rating': rating,
      'tags': tags,
      'is_accessible': isAccessible,
      'has_changing_table': hasChangingTable,
      'is_free': isFree,
      'cleanliness_rating': cleanlinessRating,
      'accessibility_rating': accessibilityRating,
      'photo_url': photoUrl,
      'operating_hours': operatingHours,
      'observations': observations,
    };
  }
}
