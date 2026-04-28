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

  Future<void> _onSearchLocation(
    SearchLocation event,
    Emitter<MapState> emit,
  ) async {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      final query = event.query.trim();
      
      if (query.isEmpty) return;

      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1'
        );

        // Cabeçalho obrigatório com User-Agent para a API Nominatim
        final response = await http.get(
          uri,
          headers: {'User-Agent': 'VivaLivreApp/1.0 (suporte@vivalivre.com)'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);

          if (data.isNotEmpty) {
            final lat = double.parse(data[0]['lat'].toString());
            final lon = double.parse(data[0]['lon'].toString());
            final newPos = LatLng(lat, lon);

            // Move a câmara (atualizando currentPosition) e limpa os pinos selecionados
            emit(currentState.copyWith(
              currentPosition: newPos,
              clearSelection: true,
              clearNearest: true,
            ));
          } else {
            emit(const MapError('Não foi possível encontrar o local. Verifique o nome e tente novamente.'));
            emit(currentState); // Re-emite o estado carregado para garantir que a UI se mantém
          }
        } else {
          emit(const MapError('Não foi possível encontrar o local. Problema na comunicação com o servidor.'));
          emit(currentState);
        }
      } on http.ClientException catch (_) {
        emit(const MapError('Erro de conexão: Verifique a sua internet.'));
        emit(currentState);
      } on FormatException catch (_) {
        emit(const MapError('Erro ao processar dados do local. Tente novamente mais tarde.'));
        emit(currentState);
      } catch (_) {
        emit(const MapError('Não foi possível encontrar o local.'));
        emit(currentState);
      }
    }
  }
}
