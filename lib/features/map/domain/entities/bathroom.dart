import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class Bathroom extends Equatable {
  final int id;
  final String name;
  final LatLng location;
  final double rating;
  final List<String> tags;
  final bool isOpen;

  const Bathroom({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.tags,
    required this.isOpen,
  });

  @override
  List<Object?> get props => [id, name, location, rating, tags, isOpen];
}
