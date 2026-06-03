part of 'add_bathroom_bloc.dart';

abstract class AddBathroomEvent extends Equatable {
  const AddBathroomEvent();

  @override
  List<Object?> get props => [];
}

/// Fired continuously while the user drags the map.
class CameraMoved extends AddBathroomEvent {
  final double latitude;
  final double longitude;

  const CameraMoved({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Fired when the user stops dragging (onCameraIdle).
/// Triggers reverse geocoding to auto-fill the address.
class CameraIdle extends AddBathroomEvent {
  final double latitude;
  final double longitude;

  const CameraIdle({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Fired when the user manually edits the address field.
class AddressEdited extends AddBathroomEvent {
  final String address;

  const AddressEdited(this.address);

  @override
  List<Object?> get props => [address];
}

/// Fired when a photo is selected via image_picker.
class PhotoSelected extends AddBathroomEvent {
  final XFile photo;

  const PhotoSelected(this.photo);

  @override
  List<Object?> get props => [photo];
}

/// Fired when the selected photo is removed.
class PhotoRemoved extends AddBathroomEvent {
  const PhotoRemoved();
}

/// Toggle accessibility switch.
class ToggleAccessible extends AddBathroomEvent {
  const ToggleAccessible();
}

/// Toggle changing table switch.
class ToggleChangingTable extends AddBathroomEvent {
  const ToggleChangingTable();
}

/// Toggle free/paid switch.
class ToggleFree extends AddBathroomEvent {
  const ToggleFree();
}

/// Fired when the user taps "Enviar Sugestão".
class SubmitBathroomRequest extends AddBathroomEvent {
  final String name;
  final String? comment;

  const SubmitBathroomRequest({required this.name, this.comment});

  @override
  List<Object?> get props => [name, comment];
}

/// Fired when the user selects an operating hours type ('unknown', '24h').
class SelectOperatingHours extends AddBathroomEvent {
  final String type;

  const SelectOperatingHours(this.type);

  @override
  List<Object?> get props => [type];
}

/// Fired when the user toggles a specific day in the custom schedule.
class ToggleDayEvent extends AddBathroomEvent {
  final int day;
  final bool isOpen;

  const ToggleDayEvent(this.day, this.isOpen);

  @override
  List<Object?> get props => [day, isOpen];
}

/// Fired when the user updates the open/close time for a specific day.
class UpdateDayTimeEvent extends AddBathroomEvent {
  final int day;
  final String openTime;
  final String closeTime;

  const UpdateDayTimeEvent(this.day, this.openTime, this.closeTime);

  @override
  List<Object?> get props => [day, openTime, closeTime];
}


