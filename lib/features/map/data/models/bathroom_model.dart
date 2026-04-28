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
    // DEFESA: usamos casts seguros (as Tipo?) com fallback ?? para cada campo.
    // Quando o mock for substituído por dados reais do Firestore, um campo
    // ausente ou com tipo inesperado não irá causar um crash de tipagem.
    return BathroomModel(
      id: (map['id'] as int?) ?? 0,
      name: (map['name'] as String?) ?? 'Sem nome',
      location: LatLng(
        (map['lat'] as num?)?.toDouble() ?? 0.0,
        (map['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isOpen: (map['open'] as bool?) ?? false,
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
