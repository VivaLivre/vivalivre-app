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
  final LatLng userPosition;
  final LatLng? targetCameraPosition;
  final List<Bathroom> bathrooms;
  final Bathroom? selectedBathroom;
  final Bathroom? nearestBathroom;
  final String? errorMessage;
  final int? actionTimestamp;

  const MapLoaded({
    required this.userPosition,
    this.targetCameraPosition,
    required this.bathrooms,
    this.selectedBathroom,
    this.nearestBathroom,
    this.errorMessage,
    this.actionTimestamp,
  });

  MapLoaded copyWith({
    LatLng? userPosition,
    LatLng? targetCameraPosition,
    List<Bathroom>? bathrooms,
    Bathroom? selectedBathroom,
    Bathroom? nearestBathroom,
    String? errorMessage,
    bool clearSelection = false,
    bool clearNearest = false,
    bool clearTargetCamera = false,
    bool clearError = false,
    int? actionTimestamp,
  }) {
    return MapLoaded(
      userPosition: userPosition ?? this.userPosition,
      targetCameraPosition: clearTargetCamera ? null : (targetCameraPosition ?? this.targetCameraPosition),
      bathrooms: bathrooms ?? this.bathrooms,
      selectedBathroom: clearSelection ? null : (selectedBathroom ?? this.selectedBathroom),
      nearestBathroom: clearNearest ? null : (nearestBathroom ?? this.nearestBathroom),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionTimestamp: actionTimestamp ?? this.actionTimestamp,
    );
  }

  @override
  List<Object?> get props => [
        userPosition,
        targetCameraPosition,
        bathrooms,
        selectedBathroom,
        nearestBathroom,
        errorMessage,
        actionTimestamp,
      ];
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object?> get props => [message];
}
