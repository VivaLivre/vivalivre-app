// ─────────────────────────────────────────────────────────────────────────────
// map_page.dart — VivaLivre
// Flutter 3.x  |  flutter_map ^8.3.0  |  latlong2 ^0.9.1
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:viva_livre_app/features/map/presentation/pages/add_bathroom_page.dart';

// ── Constantes de layout e paleta ─────────────────────────────────────────────

const _kBlue = Color(0xFF2563EB);
const _kBlueSoft = Color(0xFFEFF6FF);
const _kBlueBorder = Color(0xFFBFDBFE);
const _kText = Color(0xFF111827);
const _kSubText = Color(0xFF6B7280);
const _kSlate = Color(0xFF94A3B8);
const _kSurface = Color(0xFFF1F5F9);
const _kInitialCenter = LatLng(-23.66070438587852, -46.43089117960558);
const _kInitialZoom = 17.0;

// ──────────────────────────────────────────────────────────────────────────────
//  BUG-1 FIX: Base de dados de teste com coordenadas LatLng exactas.
//  NUNCA geocodificar por texto — os pontos ficam nas ruas erradas.
// ──────────────────────────────────────────────────────────────────────────────
const List<Map<String, dynamic>> _kBathroomsDb = [
  {
    'id': 1,
    'name': 'Minha Casa',
    'lat': -23.66070438587852,
    'lng': -46.43089117960558,
    'rating': 5.0,
    'tags': ['Privado', 'Acessível'],
    'open': true,
  },
  {
    'id': 2,
    'name': 'Nagumo',
    'lat': -23.665294452821797,
    'lng': -46.43136054859557,
    'rating': 4.5,
    'tags': ['Comercial', 'Limpo'],
    'open': true,
  },
  {
    'id': 3,
    'name': 'Shopping Mauá',
    'lat': -23.664299865247912,
    'lng': -46.46064939262508,
    'rating': 4.8,
    'tags': ['Acessível', 'Público'],
    'open': true,
  },
  {
    'id': 4,
    'name': 'Casa da Camila',
    'lat': -23.666502436775666,
    'lng': -46.52222072078094,
    'rating': 5.0,
    'tags': ['Privado', 'Seguro'],
    'open': true,
  },
];

// ═════════════════════════════════════════════════════════════════════════════
//  MapPage
// ═════════════════════════════════════════════════════════════════════════════

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // BUG-4 FIX: posição inicial = casa do utilizador, não GPS nem coordenadas
  // aleatórias de "Santo André".
  LatLng _currentPosition = _kInitialCenter;

  int? _selectedPin;
  bool _showEmergency = false;
  bool _isLocating = false;

  // Instância reutilizável do calculador de distância (latlong2).
  final Distance _distance = const Distance();

  @override
  void initState() {
    super.initState();
    // Pede localização automaticamente ao abrir o mapa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRealGps();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── GPS real (apenas quando o utilizador prime o botão "Localizar") ──────────

  Future<void> _fetchRealGps() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      // ── 1. Verifica se o serviço de GPS está ligado ──────────────────────────
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('GPS desativado. Ativa o GPS nas definições do dispositivo.');
        return;
      }

      // ── 2. Verifica / pede permissão ─────────────────────────────────────────
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('Permissão de localização negada.');
        return;
      }

      // ── 2.5. VERIFICAÇÃO DE PRECISÃO (EXATA VS APROXIMADA) ───────────────────
      // Verifica se o usuário escolheu a bolinha "Aproximada" na tela do Android 12+
      final accuracy = await Geolocator.getLocationAccuracy();
      if (accuracy == LocationAccuracyStatus.reduced) {
        _showSnack('O VivaLivre precisa da localização EXATA para achar banheiros. Altere nas configurações.');
        
        // Opcional: Abre as configurações do celular direto para a pessoa arrumar
        await Future.delayed(const Duration(seconds: 2));
        await Geolocator.openAppSettings();
        return;
      }

      // ── 3. CRÍTICO: Limpeza de cache — descarta a última posição conhecida ───
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

      // ── 5. Pede posição FRESCA ao chip GPS ───────────────────────────────────
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      if (!mounted) return;

      if (pos.accuracy > 50) {
        _showSnack(
          'Precisão baixa (±${pos.accuracy.toInt()} m). '
          'Vai para um local aberto para melhor sinal GPS.',
        );
      }

      final newPos = LatLng(pos.latitude, pos.longitude);
      setState(() => _currentPosition = newPos);
      _animatedMove(newPos, _kInitialZoom);

    } on TimeoutException {
      if (mounted) {
        _showSnack('GPS sem sinal. Vai para um local aberto e tenta novamente.');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Não foi possível obter a localização real: $e');
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ── "Achar Banheiro Agora" ────────────────────────────────────────────────
  //  BUG-1 FIX: cálculo matemático com Distance() do latlong2.
  //  Nenhuma chamada de rede, nenhum geocoding.

  void _handleFindNearest() {
    Vibration.vibrate(duration: 150, amplitude: 255);
    setState(() => _showEmergency = true);

    // Encontra o banheiro matematicamente mais próximo usando Distance()
    Map<String, dynamic>? nearest;
    double nearestMeters = double.infinity;

    for (final b in _kBathroomsDb) {
      final meters = _distance.as(
        LengthUnit.Meter,
        _currentPosition,
        LatLng(b['lat'] as double, b['lng'] as double),
      );
      if (meters < nearestMeters) {
        nearestMeters = meters;
        nearest = b;
      }
    }

    if (nearest != null) {
      final target = LatLng(nearest['lat'] as double, nearest['lng'] as double);

      _animatedMove(target, _kInitialZoom);

      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        setState(() {
          _showEmergency = false;
          _selectedPin = nearest!['id'] as int;
        });
      });
    } else {
      if (mounted) setState(() => _showEmergency = false);
    }
  }

  // ── Animação suave do mapa ────────────────────────────────────────────────

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

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Distância em texto legível (usa latlong2, sem Geolocator) ────────────

  String _formatDistance(Map<String, dynamic> bathroom) {
    final meters = _distance.as(
      LengthUnit.Meter,
      _currentPosition,
      LatLng(bathroom['lat'] as double, bathroom['lng'] as double),
    );
    if (meters < 1000) return '${meters.toInt()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Flutter Map ────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // BUG-4 FIX: centro inicial = casa do utilizador (-23.681121, -46.435728)
              initialCenter: _kInitialCenter,
              initialZoom: _kInitialZoom,
              onTap: (_, __) {
                if (_selectedPin != null) setState(() => _selectedPin = null);
              },
            ),
            children: [
              // ── Tile Layer ─────────────────────────────────────────────────
              // CartoDB Positron: Design minimalista e médico, tons de cinza suaves.
              // Base de dados: OpenStreetMap (mesmas ruas), renderização limpa.
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.vivalivre.app',

                // Cache agressivo: evita re-downloads e garante que tiles
                // já carregados continuam visíveis ao fazer pan/zoom.
                maxNativeZoom: 19,
                maxZoom: 22,

                // Fallback visual enquanto o tile ainda está a carregar.
                errorTileCallback: (tile, error, stackTrace) {
                  // tile falhou → não mostra nada (padrão), sem crash.
                },
              ),

              // ── Marker Layer ───────────────────────────────────────────────
              MarkerLayer(
                markers: [
                  // Marcador da posição actual — bolinha vermelha sólida
                  _buildCurrentLocationMarker(),

                  // Marcadores dos banheiros — círculo azul com ícone WC
                  ..._kBathroomsDb.map(_buildBathroomMarker),
                ],
              ),
            ],
          ),

          // ── Loading spinner do GPS ─────────────────────────────────────────
          if (_isLocating)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
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

          // ── Barra de busca superior ────────────────────────────────────────
          _TopBar(
            searchController: _searchController,
            openCount: _kBathroomsDb.where((b) => b['open'] == true).length,
            isLocating: _isLocating,
            onLocate: _fetchRealGps,
          ),

          // ── Overlay de emergência ──────────────────────────────────────────
          if (_showEmergency) const _EmergencyOverlay(),

          // ── FABs + card inferior ───────────────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            // Margem de segurança acima da BottomNavigationBar
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Card do pino selecionado
                if (_selectedPin != null && !_showEmergency) ...[
                  _LocationCard(
                    bathroom: _kBathroomsDb.firstWhere(
                      (b) => b['id'] == _selectedPin,
                    ),
                    distanceText: _formatDistance(
                      _kBathroomsDb.firstWhere((b) => b['id'] == _selectedPin),
                    ),
                    onClose: () => setState(() => _selectedPin = null),
                  ),
                  const SizedBox(height: 12),
                ],
                // Linha de FABs
                _FabRow(
                  onFindNearest: _handleFindNearest,
                  onAddBathroom: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddBathroomPage()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Builders de marcadores ────────────────────────────────────────────────

  // Posição actual — bolinha vermelha sólida
  Marker _buildCurrentLocationMarker() {
    return Marker(
      point: _currentPosition,
      width: 48,
      height: 48,
      // BUG-2 FIX: Alignment.center — pino cravado na coordenada exacta.
      alignment: Alignment.center,
      child: const _CurrentLocationDot(),
    );
  }

  // Banheiro — círculo azul com ícone WC
  Marker _buildBathroomMarker(Map<String, dynamic> b) {
    final isSelected = _selectedPin == b['id'];
    return Marker(
      point: LatLng(b['lat'] as double, b['lng'] as double),
      width: 44,
      height: 44,
      // BUG-2 FIX: Alignment.center garante que o centro do widget
      // coincide com a coordenada geográfica. Alignment.topCenter
      // deslocaria o marcador ~22 px para sul no ecrã.
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {
          Vibration.vibrate(duration: 30);
          setState(() => _selectedPin = isSelected ? null : b['id'] as int);
          _animatedMove(
            LatLng(b['lat'] as double, b['lng'] as double),
            _kInitialZoom,
          );
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
}

// ═════════════════════════════════════════════════════════════════════════════
//  _CurrentLocationDot — bolinha vermelha com pulso animado
// ═════════════════════════════════════════════════════════════════════════════

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
          // Anel pulsante vermelho
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
          // Núcleo vermelho sólido
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

// ═════════════════════════════════════════════════════════════════════════════
//  _TopBar — barra de busca superior
// ═════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final int openCount;
  final bool isLocating;
  final VoidCallback onLocate;

  const _TopBar({
    required this.searchController,
    required this.openCount,
    required this.isLocating,
    required this.onLocate,
  });

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
                  // Campo de busca (visual apenas — sem geocoding)
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kSurface),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.search_rounded, color: _kSlate, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: const InputDecoration(
                                hintText: 'Buscar banheiros...',
                                hintStyle: TextStyle(color: _kSlate, fontSize: 15),
                                border: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Botão "Localizar com GPS real"
                  GestureDetector(
                    onTap: onLocate,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kSurface),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isLocating
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kBlue,
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              color: _kBlue,
                              size: 22,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Brand chip
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _kBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.wc, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'VivaLivre',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Text(
                    ' · ',
                    style: TextStyle(color: _kSlate, fontSize: 13),
                  ),
                  Text(
                    '$openCount banheiros próximos',
                    style: const TextStyle(color: _kSlate, fontSize: 12),
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

// ═════════════════════════════════════════════════════════════════════════════
//  _LocationCard — card que aparece ao selecionar um pino
// ═════════════════════════════════════════════════════════════════════════════

class _LocationCard extends StatelessWidget {
  final Map<String, dynamic> bathroom;
  final String distanceText;
  final VoidCallback onClose;

  const _LocationCard({
    required this.bathroom,
    required this.distanceText,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = bathroom['open'] as bool;
    final tags = bathroom['tags'] as List;

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
          // Cabeçalho
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status aberto/fechado
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOpen
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOpen ? 'Aberto agora' : 'Fechado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOpen
                                ? const Color(0xFF059669)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bathroom['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$distanceText de distância',
                      style: const TextStyle(fontSize: 13, color: _kSubText),
                    ),
                  ],
                ),
              ),
              // Botão fechar
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: _kSubText,
                  ),
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
              ...tags.map(
                (tag) => _TagChip(
                  label: tag as String,
                  bg: _kBlueSoft,
                  border: _kBlueBorder,
                  fg: _kBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Botões de acção
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: const Text('Ir agora'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFF374151),
                  ),
                  label: const Text(
                    'Detalhes',
                    style: TextStyle(color: Color(0xFF374151)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

// ═════════════════════════════════════════════════════════════════════════════
//  _TagChip
// ═════════════════════════════════════════════════════════════════════════════

class _TagChip extends StatelessWidget {
  final String label;
  final Color bg, border, fg;
  final IconData? icon;

  const _TagChip({
    required this.label,
    required this.bg,
    required this.border,
    required this.fg,
    this.icon,
  });

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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  _EmergencyOverlay — overlay azul animado durante a busca
// ═════════════════════════════════════════════════════════════════════════════

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

// ═════════════════════════════════════════════════════════════════════════════
//  _FabRow — FAB "Achar Banheiro Agora" + FAB "Adicionar"
// ═════════════════════════════════════════════════════════════════════════════

class _FabRow extends StatelessWidget {
  final VoidCallback onFindNearest;
  final VoidCallback onAddBathroom;

  const _FabRow({
    required this.onFindNearest,
    required this.onAddBathroom,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Pílula "Achar Banheiro Agora"
        Expanded(
          child: GestureDetector(
            onTap: onFindNearest,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: _kBlue,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: 0.45),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // FAB "Adicionar banheiro"
        GestureDetector(
          onTap: onAddBathroom,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _kSurface),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: _kBlue, size: 26),
          ),
        ),
      ],
    );
  }
}