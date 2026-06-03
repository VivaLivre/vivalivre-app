part of 'add_bathroom_bloc.dart';

enum SubmissionStatus { idle, loading, success, error }

class AddBathroomState extends Equatable {
  final double latitude;
  final double longitude;
  final String address;
  final bool isGeocodingAddress;
  final XFile? photo;
  final bool isAccessible;
  final bool hasChangingTable;
  final bool isFree;
  final String operatingHoursType;
  final Map<int, Map<String, String>> customSchedule;
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
    this.operatingHoursType = 'unknown',
    this.customSchedule = const {
      1: {'open': '08:00', 'close': '18:00'},
      2: {'open': '08:00', 'close': '18:00'},
      3: {'open': '08:00', 'close': '18:00'},
      4: {'open': '08:00', 'close': '18:00'},
      5: {'open': '08:00', 'close': '18:00'},
    },
    this.submissionStatus = SubmissionStatus.idle,
    this.errorMessage,
  });

  AddBathroomState copyWith({
    double? latitude,
    double? longitude,
    String? address,
    bool? isGeocodingAddress,
    XFile? photo,
    bool clearPhoto = false,
    bool? isAccessible,
    bool? hasChangingTable,
    bool? isFree,
    String? operatingHoursType,
    Map<int, Map<String, String>>? customSchedule,
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
      operatingHoursType: operatingHoursType ?? this.operatingHoursType,
      customSchedule: customSchedule ?? this.customSchedule,
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
        operatingHoursType,
        customSchedule,
        submissionStatus,
        errorMessage,
      ];
}
