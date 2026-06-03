part of 'add_bathroom_bloc.dart';

enum SubmissionStatus { idle, loading, success, error }

class AddBathroomState extends Equatable {
  final double latitude;
  final double longitude;
  final String address;
  final bool isGeocodingAddress;
  final File? photo;
  final bool isAccessible;
  final bool hasChangingTable;
  final bool isFree;
  final SubmissionStatus submissionStatus;
  final String? errorMessage;

  const AddBathroomState({
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.address = '',
    this.isGeocodingAddress = false,
    this.photo,
    this.isAccessible = false,
    this.hasChangingTable = false,
    this.isFree = true,
    this.submissionStatus = SubmissionStatus.idle,
    this.errorMessage,
  });

  AddBathroomState copyWith({
    double? latitude,
    double? longitude,
    String? address,
    bool? isGeocodingAddress,
    File? photo,
    bool clearPhoto = false,
    bool? isAccessible,
    bool? hasChangingTable,
    bool? isFree,
    SubmissionStatus? submissionStatus,
    String? errorMessage,
  }) {
    return AddBathroomState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      isGeocodingAddress: isGeocodingAddress ?? this.isGeocodingAddress,
      photo: clearPhoto ? null : (photo ?? this.photo),
      isAccessible: isAccessible ?? this.isAccessible,
      hasChangingTable: hasChangingTable ?? this.hasChangingTable,
      isFree: isFree ?? this.isFree,
      submissionStatus: submissionStatus ?? SubmissionStatus.idle,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        address,
        isGeocodingAddress,
        photo?.path,
        isAccessible,
        hasChangingTable,
        isFree,
        submissionStatus,
        errorMessage,
      ];
}
