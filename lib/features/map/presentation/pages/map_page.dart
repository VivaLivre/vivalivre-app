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
import 'package:viva_livre_app/features/map/presentation/bloc/map_bloc.dart';
import 'package:viva_livre_app/features/map/presentation/pages/add_bathroom_page.dart';
import 'package:viva_livre_app/features/map/presentation/widgets/bathroom_card.dart';
import 'package:viva_livre_app/features/map/presentation/widgets/emergency_button.dart';
import 'package:viva_livre_app/features/map/presentation/widgets/map_search_bar.dart';

const _kBlue = Color(0xFF2563EB);
const _kInitialZoom = 17.0;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _showEmergency = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapBloc>().add(const RequestGpsLocation());
    });
  }

  @override
  void dispose() {
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

    final ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    final anim = CurvedAnimation(parent: ctrl, curve: Curves.fastOutSlowIn);

    ctrl.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(anim), lngTween.evaluate(anim)),
        zoomTween.evaluate(anim),
      );
    });

    anim.addStatusListener((s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        ctrl.dispose();
      }
    });

    ctrl.forward();
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
            color: isSelected ? _kBlue : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _kBlue, width: 3),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: isSelected ? 0.35 : 0.15),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.wc,
            size: 20,
            color: isSelected ? Colors.white : _kBlue,
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
    return Scaffold(
      body: BlocConsumer<MapBloc, MapState>(
        listener: (context, state) {
          if (state is MapError) {
            _showSnack(state.message);
          }
          if (state is MapLoaded) {
            if (_showEmergency) {
              if (state.nearestBathroom != null && state.selectedBathroom != null) {
                _animatedMove(state.selectedBathroom!.location, _kInitialZoom);
                Future.delayed(const Duration(milliseconds: 1100), () {
                  if (!mounted) return;
                  setState(() => _showEmergency = false);
                });
              } else {
                setState(() => _showEmergency = false);
              }
            } else if (state.selectedBathroom == null && state.currentPosition != const LatLng(-23.66070438587852, -46.43089117960558)) {
              // Move camera if position is updated via search and nothing is selected
              _animatedMove(state.currentPosition, _kInitialZoom);
            }
          }
        },
        builder: (context, state) {
          LatLng currentPosition = const LatLng(-23.66070438587852, -46.43089117960558);
          List<Bathroom> bathrooms = [];
          Bathroom? selectedPin;
          bool isLocating = state is MapLoading;

          if (state is MapLoaded) {
            currentPosition = state.currentPosition;
            bathrooms = state.bathrooms;
            selectedPin = state.selectedBathroom;
          }

          int openCount = bathrooms.where((b) => b.isOpen).length;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentPosition,
                  initialZoom: _kInitialZoom,
                  onTap: (_, __) {
                    if (selectedPin != null) {
                      context.read<MapBloc>().add(const ClearSelection());
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.vivalivre.app',
                    maxNativeZoom: 19,
                    maxZoom: 22,
                    errorTileCallback: (tile, error, stackTrace) {},
                  ),
                  MarkerLayer(
                    markers: [
                      _buildCurrentLocationMarker(currentPosition),
                      ...bathrooms.map((b) => _buildBathroomMarker(b, selectedPin)),
                    ],
                  ),
                ],
              ),

              if (isLocating)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.3),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: _kBlue, strokeWidth: 3),
                              SizedBox(height: 16),
                              Text(
                                'A procurar satélites...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
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
                onLocate: () {
                  FocusScope.of(context).unfocus();
                  context.read<MapBloc>().add(const RequestGpsLocation());
                },
                onSearch: (query) {
                  FocusScope.of(context).unfocus();
                  context.read<MapBloc>().add(SearchLocation(query));
                },
              ),

              if (_showEmergency) const _EmergencyOverlay(),

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
                        distanceText: _formatDistance(currentPosition, selectedPin),
                        onClose: () => context.read<MapBloc>().add(const ClearSelection()),
                      ),
                      const SizedBox(height: 12),
                    ],
                    EmergencyButton(
                      onEmergency: _handleFindNearest,
                      onAddBathroom: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddBathroomPage()),
                      ),
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

class _CurrentLocationDotState extends State<_CurrentLocationDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _anim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
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
      builder: (_, __) => Stack(
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
                  color: Colors.red.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.shade600,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.45),
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
              color: _kBlue,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _kBlue.withValues(alpha: 0.40),
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
