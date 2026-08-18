// ─────────────────────────────────────────────────────────────────────────────
// map_page.dart — VivaLivre
// Flutter 3.x  |  flutter_map ^8.3.0  |  latlong2 ^0.9.1
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:viva_livre_app/features/map/domain/entities/bathroom.dart';
import 'package:viva_livre_app/features/map/presentation/bloc/map_bloc.dart' hide MapEvent;
import 'package:viva_livre_app/features/map/presentation/bloc/add_bathroom_bloc.dart';
import 'package:viva_livre_app/features/map/presentation/pages/add_bathroom_page.dart';
import 'package:viva_livre_app/features/map/domain/repositories/i_bathroom_repository.dart';
import 'package:viva_livre_app/features/map/presentation/widgets/bathroom_card.dart';
import 'package:viva_livre_app/features/map/presentation/widgets/emergency_button.dart';
import 'package:viva_livre_app/features/map/presentation/widgets/map_search_bar.dart';
import 'package:viva_livre_app/features/ratings/presentation/pages/ratings_page.dart';

const _kInitialZoom = 17.0;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _showEmergency = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapBloc>().add(const RequestGpsLocation());
    });
  }

  @override
  void dispose() {
    _moveController?.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  AnimationController? _moveController;

  void _animatedMove(LatLng dest, double zoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: dest.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: dest.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: zoom,
    );

    _moveController?.dispose();

    _moveController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    final anim = CurvedAnimation(parent: _moveController!, curve: Curves.fastOutSlowIn);

    _moveController!.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(anim), lngTween.evaluate(anim)),
        zoomTween.evaluate(anim),
      );
    });

    _moveController!.forward();
  }

  Marker _buildCurrentLocationMarker(LatLng position) {
    return Marker(
      point: position,
      width: 48,
      height: 48,
      alignment: Alignment.center,
      child: const _CurrentLocationDot(),
    );
  }

  Marker _buildBathroomMarker(Bathroom bathroom, Bathroom? selectedPin) {
    final isSelected = selectedPin?.id == bathroom.id;
    final isOpen = bathroom.isOpen;
    final pinColor = isOpen ? Theme.of(context).colorScheme.primary : const Color(0xFF9CA3AF);
    return Marker(
      point: bathroom.location,
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {
          Vibration.vibrate(duration: 30);
          if (isSelected) {
            context.read<MapBloc>().add(const ClearSelection());
          } else {
            context.read<MapBloc>().add(SelectBathroomPin(bathroom));
            _animatedMove(bathroom.location, _kInitialZoom);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? pinColor : Theme.of(context).cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: pinColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: pinColor.withValues(alpha: isSelected ? 0.35 : 0.15),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.wc,
            size: 20,
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : pinColor,
          ),
        ),
      ),
    );
  }

  void _handleFindNearest() {
    Vibration.vibrate(duration: 150, amplitude: 255);
    setState(() => _showEmergency = true);
    context.read<MapBloc>().add(const FindNearestBathroom());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: BlocConsumer<MapBloc, MapState>(
        listener: (context, state) {
          if (state is MapError) {
            _showSnack(state.message);
          }
          if (state is MapLoaded) {
            if (state.targetCameraPosition != null) {
              _animatedMove(state.targetCameraPosition!, _mapController.camera.zoom < 15 ? _kInitialZoom : _mapController.camera.zoom);
              context.read<MapBloc>().add(const CameraMovementHandled());
            }

            if (_showEmergency) {
              if (state.nearestBathroom != null &&
                  state.selectedBathroom != null) {
                _animatedMove(state.selectedBathroom!.location, _kInitialZoom);
                Future.delayed(const Duration(milliseconds: 1100), () {
                  if (!mounted) return;
                  setState(() => _showEmergency = false);
                });
              } else {
                setState(() => _showEmergency = false);
              }
            }
          }
        },
        builder: (context, state) {
          LatLng userPosition = const LatLng(
            -23.66070438587852,
            -46.43089117960558,
          );
          List<Bathroom> bathrooms = [];
          Bathroom? selectedPin;
          bool isLocating = state is MapLoading;

          if (state is MapLoaded) {
            userPosition = state.userPosition;
            bathrooms = state.bathrooms;
            selectedPin = state.selectedBathroom;
          }

          int openCount = bathrooms.where((b) => b.isOpen).length;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userPosition,
                  initialZoom: _kInitialZoom,
                  minZoom: 4.5,
                  maxZoom: 18.0,
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(const LatLng(-90.0, -180.0), const LatLng(90.0, 180.0)),
                  ),
                  onTap: (_, _) {
                    if (selectedPin != null) {
                      context.read<MapBloc>().add(const ClearSelection());
                    }
                  },
                  onMapEvent: (MapEvent event) {
                    if (event is MapEventMoveEnd) {
                      final zoom = _mapController.camera.zoom;
                      
                      // Limite de zoom ajustado (meio termo): desaparecem ao ver uma região ampla (zoom < 10.0)
                      if (zoom < 10.0) {
                        context.read<MapBloc>().add(const ClearBathroomsEvent());
                        return;
                      }

                      final center = _mapController.camera.center;
                      final bounds = _mapController.camera.visibleBounds;
                      
                      // Calcular raio visível no mapa em metros
                      final distance = const Distance();
                      double radiusInMeters = distance.as(
                        LengthUnit.Meter,
                        center,
                        bounds.northEast,
                      );
                      
                      // Margem de segurança de 20% e limite máximo de 80km
                      radiusInMeters = (radiusInMeters * 1.2).clamp(100.0, 80000.0);

                      context.read<MapBloc>().add(FetchBathroomsInArea(center, radiusInMeters));
                    }
                  },
                ),
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      BlendMode.color,
                    ),
                    child: TileLayer(
                      urlTemplate: Theme.of(context).brightness == Brightness.dark
                          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                          : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.vivalivre.app',
                      maxNativeZoom: 19,
                      maxZoom: 22,
                      tileBounds: LatLngBounds(const LatLng(-90.0, -180.0), const LatLng(90.0, 180.0)),
                      errorTileCallback: (tile, error, stackTrace) {},
                    ),
                  ),
                  MarkerLayer(
                    markers: [
                      _buildCurrentLocationMarker(userPosition),
                      ...bathrooms.map(
                        (b) => _buildBathroomMarker(b, selectedPin),
                      ),
                    ],
                  ),
                ],
              ),

              if (isLocating)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'A procurar satélites...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              MapSearchBar(
                searchController: _searchController,
                openCount: openCount,
                isLocating: isLocating,
                currentPosition: userPosition,
                onLocate: () {
                  FocusScope.of(context).unfocus();
                  context.read<MapBloc>().add(const CenterCameraOnUserEvent());
                },
                onSuggestionSelected: (location) {
                  FocusScope.of(context).unfocus();
                  context.read<MapBloc>().add(MoveToLocation(location));
                },
              ),

              if (_showEmergency) const _EmergencyOverlay(),

              // Gradient at the bottom to blend buttons with the map
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 180,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedPin != null && !_showEmergency) ...[
                         BathroomCard(
                           bathroom: selectedPin,
                           distanceText: _formatDistance(
                             userPosition,
                             selectedPin,
                           ),
                         onClose: () =>
                             context.read<MapBloc>().add(const ClearSelection()),
                         onDetails: () {
                           final pin = selectedPin;
                           if (pin != null) {
                             Navigator.of(context).push(
                               MaterialPageRoute(
                                 builder: (_) => RatingsPage(
                                   bathroomId: pin.id.toString(),
                                   bathroomName: pin.name,
                                   bathroom: pin,
                                 ),
                               ),
                             );
                           }
                         },
                       ),
                       const SizedBox(height: 12),
                     ],
                    EmergencyButton(
                      onEmergency: _handleFindNearest,
                      onAddBathroom: () {
                        // Passar a posição central da câmara para adicionar o banheiro
                        // É mais intuitivo pois o usuário pode ter arrastado o mapa para onde quer adicionar
                        final pos = _mapController.camera.center;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => AddBathroomBloc(
                                repository: context.read<IBathroomRepository>(),
                              ),
                              child: AddBathroomPage(initialPosition: pos),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDistance(LatLng from, Bathroom to) {
    const distance = Distance();
    final meters = distance.as(LengthUnit.Meter, from, to.location);
    if (meters < 1000) return '${meters.toInt()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class _CurrentLocationDot extends StatefulWidget {
  const _CurrentLocationDot();

  @override
  State<_CurrentLocationDot> createState() => _CurrentLocationDotState();
}

class _CurrentLocationDotState extends State<_CurrentLocationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _anim = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 1.0 + _anim.value,
            child: Opacity(
              opacity: 1.0 - _anim.value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
              border: Border.all(color: Theme.of(context).cardColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyOverlay extends StatelessWidget {
  const _EmergencyOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.40),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 36, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Localizando...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Banheiro mais próximo',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
