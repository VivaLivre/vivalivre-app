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

class SearchLocation extends MapEvent {
  final String query;
  const SearchLocation(this.query);

  @override
  List<Object?> get props => [query];
}

