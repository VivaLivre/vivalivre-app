part of 'map_bloc.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {
  const MapInitial();
}

class MapLoading extends MapState {
  const MapLoading();
}

class MapLoaded extends MapState {
  final LatLng currentPosition;
  final List<Bathroom> bathrooms;
  final Bathroom? selectedBathroom;
  final Bathroom? nearestBathroom;

  const MapLoaded({
    required this.currentPosition,
    required this.bathrooms,
    this.selectedBathroom,
    this.nearestBathroom,
  });

  MapLoaded copyWith({
    LatLng? currentPosition,
    List<Bathroom>? bathrooms,
    Bathroom? selectedBathroom,
    Bathroom? nearestBathroom,
    bool clearSelection = false,
    bool clearNearest = false,
  }) {
    return MapLoaded(
      currentPosition: currentPosition ?? this.currentPosition,
      bathrooms: bathrooms ?? this.bathrooms,
      selectedBathroom: clearSelection ? null : (selectedBathroom ?? this.selectedBathroom),
      nearestBathroom: clearNearest ? null : (nearestBathroom ?? this.nearestBathroom),
    );
  }

  @override
  List<Object?> get props => [currentPosition, bathrooms, selectedBathroom, nearestBathroom];
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object?> get props => [message];
}
