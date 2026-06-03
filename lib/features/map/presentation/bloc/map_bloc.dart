import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:viva_livre_app/features/map/domain/entities/bathroom.dart';
import 'package:viva_livre_app/features/map/domain/repositories/i_bathroom_repository.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final IBathroomRepository _repository;

  /// Exposes the repository for use by child BLoCs (e.g. AddBathroomBloc).
  IBathroomRepository get repository => _repository;
  
  // Posição de fallback original da map_page
  static const LatLng _kFallbackPosition = LatLng(-23.66070438587852, -46.43089117960558);

  MapBloc({required IBathroomRepository repository})
      : _repository = repository,
        super(const MapInitial()) {
    on<RequestGpsLocation>(_onRequestGpsLocation);
    on<FindNearestBathroom>(_onFindNearestBathroom);
    on<SelectBathroomPin>(_onSelectBathroomPin);
    on<ClearSelection>(_onClearSelection);
    on<MoveToLocation>(_onMoveToLocation);
  }

  Future<void> _onRequestGpsLocation(
    RequestGpsLocation event,
    Emitter<MapState> emit,
  ) async {
    emit(const MapLoading());

    LatLng currentPosition = _kFallbackPosition;

    try {
      // ── 1. Verifica se o serviço de GPS está ligado ──
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const MapError('GPS desativado. Ativa o GPS nas definições do dispositivo.'));
      } else {
        // ── 2. Verifica / pede permissão ──
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          emit(const MapError('Permissão de localização negada. Usando posição padrão.'));
        } else {
          // ── 2.5. Verificação de Precisão ──
          final accuracy = await Geolocator.getLocationAccuracy();
          if (accuracy == LocationAccuracyStatus.reduced) {
            emit(const MapError('O VivaLivre precisa da localização EXATA. Altere nas configurações.'));
            await Future.delayed(const Duration(seconds: 2));
            await Geolocator.openAppSettings();
          } else {
            // ── 3. Limpeza de cache — descarta a última posição conhecida ──
            final LocationSettings locationSettings;
            if (defaultTargetPlatform == TargetPlatform.android) {
              locationSettings = AndroidSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                forceLocationManager: true,
                timeLimit: const Duration(seconds: 15),
              );
            } else if (defaultTargetPlatform == TargetPlatform.iOS ||
                       defaultTargetPlatform == TargetPlatform.macOS) {
              locationSettings = AppleSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                activityType: ActivityType.fitness,
                timeLimit: const Duration(seconds: 15),
                pauseLocationUpdatesAutomatically: false,
              );
            } else {
              locationSettings = const LocationSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                timeLimit: Duration(seconds: 15),
              );
            }

            // ── 5. Pede posição FRESCA ao chip GPS ──
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: locationSettings,
            );

            currentPosition = LatLng(pos.latitude, pos.longitude);

            if (pos.accuracy > 50) {
              emit(MapError('Precisão baixa (±${pos.accuracy.toInt()} m). Vai para um local aberto.'));
            }
          }
        }
      }
    } on TimeoutException {
      emit(const MapError('GPS sem sinal. Vai para um local aberto e tenta novamente.'));
    } catch (e) {
      emit(MapError('Não foi possível obter a localização real: $e'));
    }

    // Após obter a localização (real ou fallback), buscar banheiros no backend
    List<Bathroom> bathrooms = [];
    try {
      bathrooms = await _repository.getBathrooms(currentPosition.latitude, currentPosition.longitude);
    } catch (e) {
      emit(MapError('Erro ao carregar banheiros: $e'));
    }

    emit(MapLoaded(
      currentPosition: currentPosition,
      bathrooms: bathrooms,
    ));
  }

  void _onFindNearestBathroom(
    FindNearestBathroom event,
    Emitter<MapState> emit,
  ) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      
      // Filter only open bathrooms for emergency
      final openBathrooms = currentState.bathrooms
          .where((b) => b.isOpen)
          .toList();

      final nearest = _repository.findNearestBathroom(
        currentState.currentPosition,
        openBathrooms,
      );

      if (nearest != null) {
        emit(currentState.copyWith(
          nearestBathroom: nearest,
          selectedBathroom: nearest,
        ));
      } else {
        emit(const MapError('Nenhum banheiro aberto encontrado na sua região.'));
        emit(currentState);
      }
    }
  }

  void _onSelectBathroomPin(
    SelectBathroomPin event,
    Emitter<MapState> emit,
  ) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(
        selectedBathroom: event.bathroom,
      ));
    }
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<MapState> emit,
  ) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(
        clearSelection: true,
        clearNearest: true,
      ));
    }
  }

  Future<void> _onMoveToLocation(
    MoveToLocation event,
    Emitter<MapState> emit,
  ) async {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      
      // Update UI quickly with the new position and loading state
      emit(const MapLoading());
      
      List<Bathroom> bathrooms = [];
      try {
        bathrooms = await _repository.getBathrooms(event.location.latitude, event.location.longitude);
        
        emit(currentState.copyWith(
          currentPosition: event.location,
          bathrooms: bathrooms,
          clearSelection: true,
          clearNearest: true,
        ));
      } catch (e) {
        emit(MapError('Erro ao carregar banheiros na nova localização: $e'));
        // Fallback to previous state
        emit(currentState.copyWith(
          currentPosition: event.location,
          clearSelection: true,
          clearNearest: true,
        ));
      }
    }
  }
}
