part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

class RequestGpsLocation extends MapEvent {
  const RequestGpsLocation();
}

class FindNearestBathroom extends MapEvent {
  const FindNearestBathroom();
}

class SelectBathroomPin extends MapEvent {
  final Bathroom bathroom;
  const SelectBathroomPin(this.bathroom);

  @override
  List<Object?> get props => [bathroom];
}

class ClearSelection extends MapEvent {
  const ClearSelection();
}

class MoveToLocation extends MapEvent {
  final LatLng location;
  const MoveToLocation(this.location);

  @override
  List<Object?> get props => [location];
}

