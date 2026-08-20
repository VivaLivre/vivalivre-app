import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:viva_livre_app/features/map/domain/repositories/i_bathroom_repository.dart';

part 'add_bathroom_event.dart';
part 'add_bathroom_state.dart';

/// BLoC responsible for managing the "Suggest a Bathroom" flow.
///
/// Handles camera movement, reverse geocoding for automatic address,
/// photo selection, and form submission (multipart upload via Dio).
class AddBathroomBloc extends Bloc<AddBathroomEvent, AddBathroomState> {
  final IBathroomRepository _repository;

  AddBathroomBloc({required IBathroomRepository repository})
      : _repository = repository,
        super(const AddBathroomState()) {
    on<CameraMoved>(_onCameraMoved);
    on<CameraIdle>(_onCameraIdle);
    on<AddressEdited>(_onAddressEdited);
    on<PhotoSelected>(_onPhotoSelected);
    on<PhotoRemoved>(_onPhotoRemoved);
    on<ToggleAccessible>(_onToggleAccessible);
    on<ToggleChangingTable>(_onToggleChangingTable);
    on<ToggleFree>(_onToggleFree);
    on<SelectOperatingHours>(_onSelectOperatingHours);
    on<ToggleDayEvent>(_onToggleDayEvent);
    on<UpdateDayTimeEvent>(_onUpdateDayTimeEvent);
    on<SubmitBathroomRequest>(_onSubmitBathroomRequest);
  }

  void _onCameraMoved(CameraMoved event, Emitter<AddBathroomState> emit) {
    // Update lat/lng immediately while dragging — no geocode yet
    emit(state.copyWith(
      latitude: event.latitude,
      longitude: event.longitude,
    ));
  }

  Future<void> _onCameraIdle(
    CameraIdle event,
    Emitter<AddBathroomState> emit,
  ) async {
    // Update position and start reverse geocoding
    emit(state.copyWith(
      latitude: event.latitude,
      longitude: event.longitude,
      isGeocodingAddress: true,
    ));

    try {
      final response = await Dio().get(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${event.latitude}&lon=${event.longitude}&zoom=18&addressdetails=1',
        options: Options(headers: {'User-Agent': 'VivaLivreApp/1.0 (suporte@vivalivre.com)'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final addressData = data['address'] as Map<String, dynamic>?;

        if (addressData != null) {
          final road = addressData['road'] ?? addressData['pedestrian'] ?? addressData['path'] ?? '';
          final houseNumber = addressData['house_number'] ?? '';
          final suburb = addressData['suburb'] ?? addressData['neighbourhood'] ?? '';
          final city = addressData['city'] ?? addressData['town'] ?? addressData['municipality'] ?? '';

          final parts = <String>[
            if (road.isNotEmpty) road + (houseNumber.isNotEmpty ? ', $houseNumber' : ''),
            if (suburb.isNotEmpty) suburb,
            if (city.isNotEmpty) city,
          ];

          final address = parts.join(' - ');
          
          emit(state.copyWith(
            address: address.isNotEmpty ? address : 'Endereço não encontrado',
            isGeocodingAddress: false,
          ));
        } else {
          emit(state.copyWith(
            address: 'Endereço não encontrado',
            isGeocodingAddress: false,
          ));
        }
      } else {
        emit(state.copyWith(
          address: 'Endereço não encontrado',
          isGeocodingAddress: false,
        ));
      }
    } catch (_) {
      emit(state.copyWith(
        address: 'Não foi possível obter o endereço',
        isGeocodingAddress: false,
      ));
    }
  }

  void _onAddressEdited(AddressEdited event, Emitter<AddBathroomState> emit) {
    emit(state.copyWith(address: event.address));
  }

  void _onPhotoSelected(PhotoSelected event, Emitter<AddBathroomState> emit) {
    emit(state.copyWith(photo: event.photo));
  }

  void _onPhotoRemoved(PhotoRemoved event, Emitter<AddBathroomState> emit) {
    emit(state.copyWith(clearPhoto: true));
  }

  void _onToggleAccessible(ToggleAccessible event, Emitter<AddBathroomState> emit) {
    emit(state.copyWith(isAccessible: !state.isAccessible));
  }

  void _onToggleChangingTable(ToggleChangingTable event, Emitter<AddBathroomState> emit) {
    emit(state.copyWith(hasChangingTable: !state.hasChangingTable));
  }

  void _onToggleFree(ToggleFree event, Emitter<AddBathroomState> emit) {
    emit(state.copyWith(isFree: !state.isFree));
  }

  void _onSelectOperatingHours(SelectOperatingHours event, Emitter<AddBathroomState> emit) {
    emit(state.copyWith(operatingHoursType: event.type));
  }

  void _onToggleDayEvent(ToggleDayEvent event, Emitter<AddBathroomState> emit) {
    final newSchedule = Map<int, Map<String, String>>.from(state.customSchedule);
    if (event.isOpen) {
      newSchedule[event.day] = {'open': '08:00', 'close': '18:00'};
    } else {
      newSchedule.remove(event.day);
    }
    emit(state.copyWith(customSchedule: newSchedule));
  }

  void _onUpdateDayTimeEvent(UpdateDayTimeEvent event, Emitter<AddBathroomState> emit) {
    final newSchedule = Map<int, Map<String, String>>.from(state.customSchedule);
    newSchedule[event.day] = {
      'open': event.openTime,
      'close': event.closeTime,
    };
    emit(state.copyWith(customSchedule: newSchedule));
  }

  Future<void> _onSubmitBathroomRequest(
    SubmitBathroomRequest event,
    Emitter<AddBathroomState> emit,
  ) async {
    // Validation
    if (event.name.trim().isEmpty) {
      emit(state.copyWith(
        submissionStatus: SubmissionStatus.error,
        errorMessage: 'O nome do local é obrigatório.',
      ));
      return;
    }

    if (state.address.isEmpty || state.address == 'Endereço não encontrado' || state.address == 'Não foi possível obter o endereço') {
      emit(state.copyWith(
        submissionStatus: SubmissionStatus.error,
        errorMessage: 'Mova o mapa para selecionar uma localização válida.',
      ));
      return;
    }

    if (state.photo == null) {
      emit(state.copyWith(
        submissionStatus: SubmissionStatus.error,
        errorMessage: 'É obrigatório enviar uma foto.',
      ));
      return;
    }

    emit(state.copyWith(submissionStatus: SubmissionStatus.loading));

    try {
      // Build operating_hours JSON string
      Map<String, dynamic> hoursMap = {'type': state.operatingHoursType};
      
      if (state.operatingHoursType == 'custom') {
        final scheduleStrMap = <String, dynamic>{};
        state.customSchedule.forEach((key, value) {
          scheduleStrMap[key.toString()] = value;
        });
        hoursMap['schedule'] = scheduleStrMap;
      }

      final operatingHoursJson = json.encode(hoursMap);

      await _repository.addBathroomRequest(
        name: event.name.trim(),
        address: state.address,
        latitude: state.latitude,
        longitude: state.longitude,
        isAccessible: state.isAccessible,
        hasChangingTable: state.hasChangingTable,
        isFree: state.isFree,
        comment: event.comment?.trim(),
        photo: state.photo,
        operatingHours: operatingHoursJson,
      );

      emit(state.copyWith(submissionStatus: SubmissionStatus.success));
    } catch (e) {
      String message = 'Falha ao enviar sugestão. Tente novamente.';
      
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data is Map && e.response?.data['error'] != null) {
          message = e.response?.data['error'];
        } else if (e.response?.statusCode == 429) {
          message = 'Limite diário de 10 requisições atingido.';
        } else if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
          message = 'Sem conexão com o servidor. Verifique a sua internet.';
        }
      } else if (e is SocketException) {
        message = 'Sem conexão com o servidor. Verifique a sua internet.';
      }

      emit(state.copyWith(
        submissionStatus: SubmissionStatus.error,
        errorMessage: message,
      ));
    }
  }
}
