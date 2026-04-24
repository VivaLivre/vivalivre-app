import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:viva_livre_app/features/map/presentation/pages/add_bathroom_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  int? _selectedPin;
  bool _showEmergency = false;
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;

  // Mock data — agora com dados de teste em Mauá, SP
  final List<Map<String, dynamic>> _bathrooms = [
    {'id': 1, 'name': 'Mauá Plaza Shopping', 'rating': 4.8, 'distance': '0.0 km', 'tags': ['Acessível', 'Limpo'], 'open': true, 'lat': -23.663803, 'lng': -46.461523},
    {'id': 2, 'name': 'Minha Casa (Jd. Miranda D\'Aviz)', 'rating': 4.1, 'distance': '0.0 km', 'tags': ['Privado', 'Público'], 'open': true, 'lat': -23.66279, 'lng': -46.43183},
    {'id': 3, 'name': 'Nagumo Barão de Mauá', 'rating': 4.5, 'distance': '0.0 km', 'tags': ['Acessível', 'Comercial'], 'open': true, 'lat': -23.6743, 'lng': -46.4526},
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => _isLoadingLocation = true);

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFallbackLocation();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setFallbackLocation();
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _setFallbackLocation();
        return;
      } 

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentPosition!, 17.0);
      }
    } catch (e) {
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    if (mounted) {
      setState(() {
        _currentPosition = const LatLng(-23.6673, -46.4616);
        _isLoadingLocation = false;
      });
      _mapController.move(_currentPosition!, 17.0);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _handleEmergency() {
    HapticFeedback.mediumImpact();
    setState(() => _showEmergency = true);
    
    // Find the closest bathroom (open, sorted by distance using latlong2)
    final distance = const Distance();
    final emergencyBathroom = _bathrooms.where((b) => b['open'] == true).toList()..sort((a, b) {
      if (_currentPosition == null) return 0;
      final distA = distance.as(LengthUnit.Meter, _currentPosition!, LatLng(a['lat'], a['lng']));
      final distB = distance.as(LengthUnit.Meter, _currentPosition!, LatLng(b['lat'], b['lng']));
      return distA.compareTo(distB);
    });
    
    if (emergencyBathroom.isNotEmpty) {
      final best = emergencyBathroom.first;
      final target = LatLng(best['lat'], best['lng']);
      
      // Animate map to emergency bathroom
      _animatedMapMove(target, 17.0);

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _showEmergency = false;
            _selectedPin = best['id'];
          });
        }
      });
    } else {
      setState(() => _showEmergency = false);
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Buscando endereço...'), duration: Duration(seconds: 1)),
    );

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 1,
        },
        options: Options(headers: {'User-Agent': 'br.com.gabriel.vivalivre'}),
      );

      if (response.data != null && response.data.isNotEmpty) {
        final result = response.data[0];
        final lat = double.parse(result['lat'].toString());
        final lon = double.parse(result['lon'].toString());
        final searchedLocation = LatLng(lat, lon);

        _animatedMapMove(searchedLocation, 17.0);

        // Find bathrooms within 25km radius
        bool foundAny = false;
        final distanceCalc = const Distance();
        for (var b in _bathrooms) {
          final bLat = b['lat'] as double;
          final bLng = b['lng'] as double;
          final distKm = distanceCalc.as(LengthUnit.Kilometer, searchedLocation, LatLng(bLat, bLng));
          if (distKm <= 25.0) {
            foundAny = true;
            break;
          }
        }

        if (!foundAny) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhum banheiro encontrado nas proximidades'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Endereço não encontrado.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao buscar endereço.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Flutter Map ────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? const LatLng(-23.6666, -46.4628), // Mauá default
              initialZoom: 17.0,
              onTap: (tapPosition, point) {
                if (_selectedPin != null) {
                  setState(() => _selectedPin = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.jose.vivalivre',
                retinaMode: true,
              ),
              MarkerLayer(
                markers: [
                  // Current location marker
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 48,
                      height: 48,
                      child: const _LocationDot(),
                    ),
                  
                  // Bathroom pins
                  ..._bathrooms.map((b) {
                    final isSelected = _selectedPin == b['id'];
                    return Marker(
                      point: LatLng(b['lat'], b['lng']),
                      width: 60,
                      height: 80,
                      alignment: Alignment.center,
                      child: _BathroomPin(
                        bathroom: b,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedPin = isSelected ? null : b['id'] as int);
                          _animatedMapMove(LatLng(b['lat'], b['lng']), 17.0); // Centralização exata
                        },
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          if (_isLoadingLocation)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
            ),

          // ── Top search bar ────────────────────────────────────────────
          _TopBar(
            controller: _searchController, 
            openCount: _bathrooms.where((b) => b['open'] == true).length,
            onLocate: () {
              if (_currentPosition != null) {
                _animatedMapMove(_currentPosition!, 17.0);
              } else {
                _determinePosition();
              }
            },
            onSearch: _searchAddress,
          ),

          // ── Emergency overlay ─────────────────────────────────────────
          if (_showEmergency) const _EmergencyOverlay(),

          // ── Cards and FABs vertically stacked ─────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location info card (when a pin is selected)
                if (_selectedPin != null && !_showEmergency) ...[
                  _LocationCard(
                    bathroom: _bathrooms.firstWhere((b) => b['id'] == _selectedPin),
                    onClose: () => setState(() => _selectedPin = null),
                    currentPosition: _currentPosition,
                  ),
                  const SizedBox(height: 16),
                ],
                // FABs (Emergency + Add)
                _FabRow(onEmergency: _handleEmergency),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing location dot ───────────────────────────────────────────────────────

class _LocationDot extends StatefulWidget {
  const _LocationDot();

  @override
  State<_LocationDot> createState() => _LocationDotState();
}

class _LocationDotState extends State<_LocationDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _anim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 1.0 + _anim.value,
            child: Opacity(
              opacity: 1.0 - _anim.value,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2563EB),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Color(0x442563EB), blurRadius: 8)],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bathroom Pin ──────────────────────────────────────────────────────────────

class _BathroomPin extends StatelessWidget {
  final Map<String, dynamic> bathroom;
  final bool isSelected;
  final VoidCallback onTap;

  const _BathroomPin({
    required this.bathroom,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = bathroom['open'] as bool;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: SizedBox(
          width: 40,
          height: 56,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // Pin body
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.white : (isOpen ? const Color(0xFF2563EB) : Colors.grey),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF2563EB).withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.15),
                      blurRadius: isSelected ? 12 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.wc_rounded,
                  size: 18,
                  color: isSelected ? Colors.white : (isOpen ? const Color(0xFF2563EB) : Colors.grey),
                ),
              ),
              // Pin tail
              Positioned(
                bottom: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  transform: Matrix4.rotationZ(0.785),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isOpen ? const Color(0xFF2563EB) : Colors.grey,
                            width: 1.5,
                          ),
                  ),
                ),
              ),
              // Rating badge
              Positioned(
                top: -4,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 9, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 1),
                      Text(
                        '${bathroom['rating']}',
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top search bar ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final TextEditingController controller;
  final int openCount;
  final VoidCallback onLocate;
  final ValueChanged<String> onSearch;

  const _TopBar({required this.controller, required this.openCount, required this.onLocate, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Search field
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              onSubmitted: onSearch,
                              decoration: const InputDecoration(
                                hintText: 'Buscar banheiros...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                                border: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Locate button
                  GestureDetector(
                    onTap: onLocate,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Color(0xFF2563EB), size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Brand chip
              Row(
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.wc_rounded, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'VivaLivre',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                  const Text(
                    ' · ',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                  Text(
                    '$openCount banheiros próximos',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Location card when pin is selected ────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final Map<String, dynamic> bathroom;
  final VoidCallback onClose;
  final LatLng? currentPosition;

  const _LocationCard({required this.bathroom, required this.onClose, this.currentPosition});

  @override
  Widget build(BuildContext context) {
    final isOpen = bathroom['open'] as bool;
    final tags = bathroom['tags'] as List;

    String distanceText = bathroom['distance'] as String;
    if (currentPosition != null) {
      final distMeters = Geolocator.distanceBetween(currentPosition!.latitude, currentPosition!.longitude, bathroom['lat'], bathroom['lng']);
      if (distMeters < 1000) {
        distanceText = '${distMeters.toInt()} m';
      } else {
        distanceText = '${(distMeters / 1000).toStringAsFixed(1)} km';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOpen ? const Color(0xFF10B981) : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpen ? 'Aberto agora' : 'Fechado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOpen ? const Color(0xFF059669) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bathroom['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$distanceText de distância',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tags
            Wrap(
              spacing: 6,
              children: [
                _TagChip(
                  icon: Icons.star_rounded,
                  label: '${bathroom['rating']}',
                  bg: const Color(0xFFFFFBEB),
                  border: const Color(0xFFFDE68A),
                  fg: const Color(0xFFB45309),
                ),
                ...tags.map((tag) => _TagChip(
                  label: tag as String,
                  bg: const Color(0xFFEFF6FF),
                  border: const Color(0xFFBFDBFE),
                  fg: const Color(0xFF2563EB),
                )),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('Ir agora'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF374151)),
                    label: const Text('Detalhes', style: TextStyle(color: Color(0xFF374151))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color bg, border, fg;
  final IconData? icon;

  const _TagChip({required this.label, required this.bg, required this.border, required this.fg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

// ── Emergency overlay ─────────────────────────────────────────────────────────

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
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.4), blurRadius: 32, spreadRadius: 4),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 36, color: Colors.white),
                SizedBox(height: 8),
                Text('Localizando...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Banheiro mais próximo', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── FAB row ───────────────────────────────────────────────────────────────────

class _FabRow extends StatelessWidget {
  final VoidCallback onEmergency;

  const _FabRow({required this.onEmergency});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Emergency pill
          Expanded(
            child: GestureDetector(
              onTap: onEmergency,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Achar Banheiro Agora',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Add bathroom FAB
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddBathroomPage()),
              );
            },
            child: Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF2563EB), size: 26),
            ),
          ),
        ],
      );
  }
}
