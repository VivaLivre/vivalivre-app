import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:viva_livre_app/features/map/domain/entities/bathroom.dart';
import 'package:viva_livre_app/features/map/domain/repositories/i_bathroom_repository.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final IBathroomRepository _repository;
  
  // Posição de fallback original da map_page
  static const LatLng _kFallbackPosition = LatLng(-23.66070438587852, -46.43089117960558);

  MapBloc({required IBathroomRepository repository})
      : _repository = repository,
        super(const MapInitial()) {
    on<RequestGpsLocation>(_onRequestGpsLocation);
    on<FindNearestBathroom>(_onFindNearestBathroom);
    on<SelectBathroomPin>(_onSelectBathroomPin);
    on<ClearSelection>(_onClearSelection);
    on<SearchLocation>(_onSearchLocation);
  }

  Future<void> _onRequestGpsLocation(
    RequestGpsLocation event,
    Emitter<MapState> emit,
  ) async {
    emit(const MapLoading());

    List<Bathroom> bathrooms = [];
    try {
      bathrooms = await _repository.getBathrooms();
    } catch (e) {
      emit(MapError('Erro ao carregar banheiros: $e'));
      // Mantém um estado carregado mesmo sem banheiros para mostrar o mapa
      emit(MapLoaded(currentPosition: _kFallbackPosition, bathrooms: const []));
      return;
    }

    try {
      // ── 1. Verifica se o serviço de GPS está ligado ──
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const MapError('GPS desativado. Ativa o GPS nas definições do dispositivo.'));
        emit(MapLoaded(currentPosition: _kFallbackPosition, bathrooms: bathrooms));
        return;
      }

      // ── 2. Verifica / pede permissão ──
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(const MapError('Permissão de localização negada.'));
        emit(MapLoaded(currentPosition: _kFallbackPosition, bathrooms: bathrooms));
        return;
      }

      // ── 2.5. Verificação de Precisão ──
      final accuracy = await Geolocator.getLocationAccuracy();
      if (accuracy == LocationAccuracyStatus.reduced) {
        emit(const MapError('O VivaLivre precisa da localização EXATA para achar banheiros. Altere nas configurações.'));
        
        await Future.delayed(const Duration(seconds: 2));
        await Geolocator.openAppSettings();
        
        emit(MapLoaded(currentPosition: _kFallbackPosition, bathrooms: bathrooms));
        return;
      }

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

      final currentPosition = LatLng(pos.latitude, pos.longitude);

      if (pos.accuracy > 50) {
        emit(MapError('Precisão baixa (±${pos.accuracy.toInt()} m). Vai para um local aberto para melhor sinal GPS.'));
      }

      emit(MapLoaded(
        currentPosition: currentPosition,
        bathrooms: bathrooms,
      ));

    } on TimeoutException {
      emit(const MapError('GPS sem sinal. Vai para um local aberto e tenta novamente.'));
      emit(MapLoaded(currentPosition: _kFallbackPosition, bathrooms: bathrooms));
    } catch (e) {
      emit(MapError('Não foi possível obter a localização real: $e'));
      emit(MapLoaded(currentPosition: _kFallbackPosition, bathrooms: bathrooms));
    }
  }

  void _onFindNearestBathroom(
    FindNearestBathroom event,
    Emitter<MapState> emit,
  ) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      
      final nearest = _repository.findNearestBathroom(
        currentState.currentPosition,
        currentState.bathrooms,
      );

      if (nearest != null) {
        emit(currentState.copyWith(
          nearestBathroom: nearest,
          selectedBathroom: nearest,
        ));
      } else {
        emit(const MapError('Nenhum banheiro encontrado na sua região.'));
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

  void _onSearchLocation(
    SearchLocation event,
    Emitter<MapState> emit,
  ) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      final query = event.query.toLowerCase().trim();
      
      if (query.isEmpty) return;

      // Busca simples na base mockada para simular a pesquisa (como "Mauá")
      try {
        final result = currentState.bathrooms.firstWhere(
          (b) => b.name.toLowerCase().contains(query) || b.tags.any((t) => t.toLowerCase().contains(query)),
        );
        
        // Move o currentPosition para o local encontrado e limpa a selecção
        emit(currentState.copyWith(
          currentPosition: result.location,
          clearSelection: true,
          clearNearest: true,
        ));
      } catch (e) {
        emit(const MapError('Local não encontrado. Tente pesquisar por um banheiro existente (ex: "Mauá").'));
        emit(currentState);
      }
    }
  }
}
