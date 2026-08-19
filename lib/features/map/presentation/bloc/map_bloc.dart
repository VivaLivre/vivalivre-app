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

  StreamSubscription<Position>? _positionSubscription;

  MapBloc({required IBathroomRepository repository})
      : _repository = repository,
        super(const MapInitial()) {
    on<RequestGpsLocation>(_onRequestGpsLocation);
    on<FindNearestBathroom>(_onFindNearestBathroom);
    on<SelectBathroomPin>(_onSelectBathroomPin);
    on<ClearSelection>(_onClearSelection);
    on<MoveToLocation>(_onMoveToLocation);
    on<CenterCameraOnUserEvent>(_onCenterCameraOnUser);
    on<CameraMovementHandled>(_onCameraMovementHandled);
    on<UserPositionUpdated>(_onUserPositionUpdated);
    on<FetchBathroomsInArea>(_onFetchBathroomsInArea);
    on<ClearBathroomsEvent>(_onClearBathrooms);
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
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
        return;
      } else {
        // ── 2. Verifica / pede permissão ──
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          emit(const MapError('Permissão de localização negada. Usando posição padrão.'));
          // Continua para buscar banheiros na posição padrão
        } else {
          // ── 2.5. Verificação de Precisão ──
          final accuracy = await Geolocator.getLocationAccuracy();
          if (accuracy == LocationAccuracyStatus.reduced) {
            emit(const MapError('O VivaLivre precisa da localização EXATA. Altere nas configurações.'));
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

            // ── 4. Pede posição FRESCA ao chip GPS ──
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: locationSettings,
            );

            currentPosition = LatLng(pos.latitude, pos.longitude);

            if (pos.accuracy > 50) {
              emit(MapError('Precisão baixa (±${pos.accuracy.toInt()} m). Vai para um local aberto.'));
            }

            // ── 5. Inicia o stream contínuo de localização (Configuração Otimizada) ──
            _positionSubscription?.cancel();
            
            final streamSettings = defaultTargetPlatform == TargetPlatform.android
                ? AndroidSettings(
                    accuracy: LocationAccuracy.bestForNavigation,
                    distanceFilter: 5, // Só emite se o usuário mover 5 metros
                    forceLocationManager: true,
                  )
                : (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)
                    ? AppleSettings(
                        accuracy: LocationAccuracy.bestForNavigation,
                        activityType: ActivityType.fitness,
                        distanceFilter: 5,
                        pauseLocationUpdatesAutomatically: false,
                      )
                    : const LocationSettings(
                        accuracy: LocationAccuracy.bestForNavigation,
                        distanceFilter: 5,
                      );

            _positionSubscription = Geolocator.getPositionStream(
              locationSettings: streamSettings,
            ).listen(
              (Position position) {
                add(UserPositionUpdated(LatLng(position.latitude, position.longitude)));
              },
              onError: (error) {
                // Log do erro silencioso para não quebrar o tracking caso o GPS perca sinal temporariamente
                debugPrint('Erro no stream de GPS: $error');
              },
            );
          }
        }
      }
    } on TimeoutException {
      emit(const MapError('GPS sem sinal. Vai para um local aberto e tenta novamente.'));
      return;
    } catch (e) {
      emit(MapError('Não foi possível obter a localização real: $e'));
      return;
    }

    // Após obter a localização (real ou fallback), buscar banheiros no backend
    List<Bathroom> bathrooms = [];
    try {
      bathrooms = await _repository.getBathrooms(currentPosition.latitude, currentPosition.longitude);
    } catch (e) {
      emit(MapError('Erro ao carregar banheiros: $e'));
      return;
    }

    emit(MapLoaded(
      userPosition: currentPosition,
      targetCameraPosition: currentPosition,
      bathrooms: bathrooms,
    ));
  }

  Future<void> _onFindNearestBathroom(
    FindNearestBathroom event,
    Emitter<MapState> emit,
  ) async {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      
      try {
        // Find bathrooms around the real user position up to 10km radius
        final bathroomsNearUser = await _repository.getBathrooms(
          currentState.userPosition.latitude,
          currentState.userPosition.longitude,
          radius: 10000,
        );

        final openBathrooms = bathroomsNearUser.where((b) => b.isOpen).toList();

        final nearest = _repository.findNearestBathroom(
          currentState.userPosition,
          openBathrooms,
        );

        if (nearest != null) {
          // Merge to ensure the nearest bathroom is in the loaded list
          final Map<String, Bathroom> bathroomMap = {
            for (var b in currentState.bathrooms) b.id.toString(): b,
            for (var b in bathroomsNearUser) b.id.toString(): b,
          };

          emit(currentState.copyWith(
            nearestBathroom: nearest,
            selectedBathroom: nearest,
            bathrooms: bathroomMap.values.toList(),
          ));
        } else {
          emit(currentState.copyWith(
            errorMessage: 'Nenhum banheiro aberto encontrado na sua região.',
          ));
          emit(currentState.copyWith(clearError: true));
        }
      } catch (e) {
        emit(currentState.copyWith(
          errorMessage: 'Erro ao buscar banheiros próximos.',
        ));
        emit(currentState.copyWith(clearError: true));
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
      
      // Apenas define a câmara, o mapa (UI) mover-se-á e disparará FetchBathroomsInArea
      emit(currentState.copyWith(
        targetCameraPosition: event.location,
        clearSelection: true,
        clearNearest: true,
      ));
    }
  }

  Future<void> _onFetchBathroomsInArea(
    FetchBathroomsInArea event,
    Emitter<MapState> emit,
  ) async {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      
      try {
        final bathrooms = await _repository.getBathrooms(
          event.center.latitude, 
          event.center.longitude,
          radius: event.radius,
        );
        
        emit(currentState.copyWith(bathrooms: bathrooms));
      } catch (e) {
        emit(MapError('Erro ao explorar mapa: $e'));
        emit(currentState); // Restaura o estado anterior (sem alterar banheiros)
      }
    }
  }

  void _onCenterCameraOnUser(
    CenterCameraOnUserEvent event,
    Emitter<MapState> emit,
  ) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(
        targetCameraPosition: currentState.userPosition,
      ));
    }
  }

  void _onCameraMovementHandled(
    CameraMovementHandled event,
    Emitter<MapState> emit,
  ) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(
        clearTargetCamera: true,
      ));
    }
  }

  void _onUserPositionUpdated(
    UserPositionUpdated event,
    Emitter<MapState> emit,
  ) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(
        userPosition: event.newPosition,
      ));
    }
  }

  void _onClearBathrooms(
    ClearBathroomsEvent event,
    Emitter<MapState> emit,
  ) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(
        bathrooms: [],
        clearSelection: true,
      ));
    }
  }
}
