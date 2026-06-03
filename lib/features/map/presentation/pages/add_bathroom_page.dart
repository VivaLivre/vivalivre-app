// ─────────────────────────────────────────────────────────────────────────────
// add_bathroom_page.dart — VivaLivre
// Uber-style bathroom suggestion page with fixed center pin
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:viva_livre_app/features/map/presentation/bloc/add_bathroom_bloc.dart';

const _kBlue = Color(0xFF2563EB);
const _kDark = Color(0xFF111827);
const _kGray = Color(0xFF9CA3AF);
const _kBg = Color(0xFFF3F4F6);
const _kCardBg = Color(0xFFF9FAFB);
const _kBorder = Color(0xFFE5E7EB);

class AddBathroomPage extends StatefulWidget {
  /// Initial position from the user's current GPS location.
  final LatLng? initialPosition;

  const AddBathroomPage({super.key, this.initialPosition});

  @override
  State<AddBathroomPage> createState() => _AddBathroomPageState();
}

class _AddBathroomPageState extends State<AddBathroomPage>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final ImagePicker _imagePicker = ImagePicker();

  late LatLng _currentCenter;
  bool _isMapReady = false;
  bool _isUserDragging = false;

  // Pin animation
  late AnimationController _pinBounceCtrl;
  late Animation<double> _pinBounce;

  @override
  void initState() {
    super.initState();
    _currentCenter =
        widget.initialPosition ?? const LatLng(-23.660704, -46.430891);

    _pinBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pinBounce = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _pinBounceCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _nameController.dispose();
    _commentController.dispose();
    _addressController.dispose();
    _sheetController.dispose();
    _pinBounceCtrl.dispose();
    super.dispose();
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (!_isMapReady) return;

    if (hasGesture) {
      if (!_isUserDragging) {
        _isUserDragging = true;
        _pinBounceCtrl.forward();
      }

      final width = MediaQuery.of(context).size.width;
      final height = MediaQuery.of(context).size.height;
      // The visual pin is centered in a Positioned.fill with bottom: height * 0.40.
      // This means its center is at height * 0.30 from the top of the screen.
      final pinOffset = Offset(width / 2, height * 0.30);
      
      // Get the exact coordinate under the visual pin
      final pinLatLng = camera.screenOffsetToLatLng(pinOffset);

      _currentCenter = pinLatLng;
      context.read<AddBathroomBloc>().add(CameraMoved(
            latitude: pinLatLng.latitude,
            longitude: pinLatLng.longitude,
          ));
    }
  }

  void _onCameraIdle() {
    if (!_isUserDragging) return;
    _isUserDragging = false;
    _pinBounceCtrl.reverse();

    context.read<AddBathroomBloc>().add(CameraIdle(
          latitude: _currentCenter.latitude,
          longitude: _currentCenter.longitude,
        ));
  }

  Future<void> _pickPhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      context.read<AddBathroomBloc>().add(PhotoSelected(picked));
    }
  }

  Future<void> _takePhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      context.read<AddBathroomBloc>().add(PhotoSelected(picked));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Adicionar Foto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
            const SizedBox(height: 20),
            _PhotoOptionTile(
              icon: Icons.camera_alt_rounded,
              label: 'Tirar Foto',
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            const SizedBox(height: 12),
            _PhotoOptionTile(
              icon: Icons.photo_library_rounded,
              label: 'Escolher da Galeria',
              onTap: () {
                Navigator.pop(context);
                _pickPhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    FocusScope.of(context).unfocus();
    context.read<AddBathroomBloc>().add(SubmitBathroomRequest(
          name: _nameController.text,
          comment: _commentController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddBathroomBloc, AddBathroomState>(
      listener: (context, state) {
        // Sync address controller when geocoding returns
        if (!state.isGeocodingAddress &&
            state.address.isNotEmpty &&
            _addressController.text != state.address) {
          _addressController.text = state.address;
        }

        // Handle submission states
        if (state.submissionStatus == SubmissionStatus.success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Sugestão enviada com sucesso! '
                        'Será analisada pela equipa.'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }

        if (state.submissionStatus == SubmissionStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.errorMessage!)),
                  ],
                ),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
        }
      },
      builder: (context, state) {
        final isLoading = state.submissionStatus == SubmissionStatus.loading;

        return Scaffold(
          body: Stack(
            children: [
              // ─── Map Background ───
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentCenter,
                    initialZoom: 17.0,
                    onMapReady: () {
                      _isMapReady = true;
                      // Trigger initial reverse geocode
                      context.read<AddBathroomBloc>().add(CameraIdle(
                            latitude: _currentCenter.latitude,
                            longitude: _currentCenter.longitude,
                          ));
                    },
                    onPositionChanged: _onMapPositionChanged,
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd ||
                          event is MapEventFlingAnimationEnd) {
                        _onCameraIdle();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.vivalivre.app',
                      maxNativeZoom: 19,
                      maxZoom: 22,
                    ),
                  ],
                ),
              ),

              // ─── Fixed Center Pin (Uber-style) ───
              Positioned.fill(
                bottom: MediaQuery.of(context).size.height * 0.40,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pinBounce,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _pinBounce.value),
                      child: child,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pin shadow when lifted
                        AnimatedBuilder(
                          animation: _pinBounce,
                          builder: (context, _) {
                            final lift =
                                (_pinBounce.value.abs() / 12).clamp(0.0, 1.0);
                            return Container(
                              width: 48 + (lift * 8),
                              height: 48 + (lift * 8),
                              decoration: BoxDecoration(
                                color: _kBlue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        _kBlue.withValues(alpha: 0.4 + lift * 0.2),
                                    blurRadius: 16 + (lift * 8),
                                    offset: Offset(0, 4 + lift * 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_location_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        // Pin drop shadow dot
                        AnimatedBuilder(
                          animation: _pinBounce,
                          builder: (context, _) {
                            final lift =
                                (_pinBounce.value.abs() / 12).clamp(0.0, 1.0);
                            return Container(
                              width: 12 - (lift * 4),
                              height: 12 - (lift * 4),
                              decoration: BoxDecoration(
                                color:
                                    _kBlue.withValues(alpha: 0.3 - lift * 0.15),
                                shape: BoxShape.circle,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Top Bar ───
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    right: 16,
                    bottom: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.7, 1.0],
                    ),
                  ),
                  child: Row(
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Sugerir Banheiro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _kDark,
                          ),
                        ),
                      ),
                      // Crosshair / re-center button
                      _CircleButton(
                        icon: Icons.my_location_rounded,
                        onTap: () {
                          if (widget.initialPosition != null) {
                            _mapController.move(
                                widget.initialPosition!, 17.0);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Address Chip (above the sheet) ───
              Positioned(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).size.height * 0.42 + 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.isGeocodingAddress) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _kBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'A procurar endereço...',
                            style: TextStyle(
                              fontSize: 13,
                              color: _kGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.location_on_rounded,
                              color: _kBlue, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              state.address.isNotEmpty
                                  ? state.address
                                  : 'Mova o mapa para selecionar',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Bottom Sheet (Form Panel) ───
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.42,
                minChildSize: 0.42,
                maxChildSize: 0.85,
                snap: true,
                snapSizes: const [0.42, 0.85],
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 20),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _kBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // ── Address Field (editable) ──
                        const _SectionLabel(
                            icon: Icons.pin_drop_rounded,
                            label: 'Endereço'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _addressController,
                          onChanged: (val) => context
                              .read<AddBathroomBloc>()
                              .add(AddressEdited(val)),
                          style: const TextStyle(fontSize: 14, color: _kDark),
                          decoration: _inputDecoration(
                            hint: 'Morada preenchida automaticamente',
                            suffixIcon: state.isGeocodingAddress
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _kBlue,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.edit_rounded,
                                    size: 18, color: _kGray),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Name Field ──
                        const _SectionLabel(
                            icon: Icons.storefront_rounded,
                            label: 'Nome do Local'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 14, color: _kDark),
                          decoration: _inputDecoration(
                            hint: 'Ex: Shopping ABCD, Posto Shell...',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Photo Section ──
                        const _SectionLabel(
                            icon: Icons.camera_alt_rounded,
                            label: 'Foto do Local'),
                        const SizedBox(height: 4),
                        const Text(
                          'Obrigatória para validação da sugestão',
                          style: TextStyle(fontSize: 12, color: _kGray),
                        ),
                        const SizedBox(height: 10),
                        _PhotoPicker(
                          photo: state.photo,
                          onAdd: _showPhotoOptions,
                          onRemove: () => context
                              .read<AddBathroomBloc>()
                              .add(const PhotoRemoved()),
                        ),
                        const SizedBox(height: 24),

                        // ── Toggles ──
                        Container(
                          decoration: BoxDecoration(
                            color: _kCardBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _ToggleRow(
                                icon: '♿',
                                label: 'Acessível para PCD',
                                value: state.isAccessible,
                                onChanged: (_) => context
                                    .read<AddBathroomBloc>()
                                    .add(const ToggleAccessible()),
                              ),
                              const Divider(height: 1, color: _kBorder),
                              _ToggleRow(
                                icon: '🍼',
                                label: 'Possui Trocador',
                                value: state.hasChangingTable,
                                onChanged: (_) => context
                                    .read<AddBathroomBloc>()
                                    .add(const ToggleChangingTable()),
                              ),
                              const Divider(height: 1, color: _kBorder),
                              _ToggleRow(
                                icon: '🆓',
                                label: 'Gratuito',
                                value: state.isFree,
                                onChanged: (_) => context
                                    .read<AddBathroomBloc>()
                                    .add(const ToggleFree()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Operating Hours ──
                        const _SectionLabel(
                            icon: Icons.schedule_rounded,
                            label: 'Horário de Funcionamento'),
                        const SizedBox(height: 4),
                        const Text(
                          'Selecione o tipo de horário',
                          style: TextStyle(fontSize: 12, color: _kGray),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _OperatingHoursChip(
                                label: 'Não sei',
                                icon: Icons.help_outline_rounded,
                                isSelected:
                                    state.operatingHoursType == 'unknown',
                                onTap: () => context
                                    .read<AddBathroomBloc>()
                                    .add(const SelectOperatingHours(
                                        'unknown')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _OperatingHoursChip(
                                label: '24 Horas',
                                icon: Icons.all_inclusive_rounded,
                                isSelected:
                                    state.operatingHoursType == '24h',
                                onTap: () => context
                                    .read<AddBathroomBloc>()
                                    .add(const SelectOperatingHours('24h')),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _OperatingHoursChip(
                          label: 'Personalizado',
                          icon: Icons.edit_calendar_rounded,
                          isSelected: state.operatingHoursType == 'custom',
                          onTap: () => context
                              .read<AddBathroomBloc>()
                              .add(const SelectOperatingHours('custom')),
                        ),
                        if (state.operatingHoursType == 'custom') ...[
                          const SizedBox(height: 16),
                          _CustomScheduleWidget(
                              customSchedule: state.customSchedule),
                        ],
                        const SizedBox(height: 24),

                        // ── Comment ──
                        Row(
                          children: [
                            const _SectionLabel(
                                icon: Icons.comment_rounded,
                                label: 'Comentário'),
                            const SizedBox(width: 6),
                            Text(
                              '(opcional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: _kGray.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 14, color: _kDark),
                          decoration: _inputDecoration(
                            hint:
                                'Dicas, observações sobre o local...',
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Submit Button ──
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kBlue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  _kBlue.withValues(alpha: 0.6),
                              disabledForegroundColor:
                                  Colors.white.withValues(alpha: 0.8),
                              minimumSize:
                                  const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'Enviar Sugestão',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),

              // ─── Full-screen loading overlay during submission ───
              if (isLoading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _kGray, fontSize: 14),
      filled: true,
      fillColor: _kBg,
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBlue, width: 2),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════════

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: _kDark, size: 20),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kBlue),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kDark,
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$icon  $label',
            style: const TextStyle(fontSize: 15, color: _kDark),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _kBlue,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD1D5DB),
          ),
        ],
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final XFile? photo;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _PhotoPicker({
    required this.photo,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: kIsWeb
                ? Image.network(
                    photo!.path,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(photo!.path),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
          // Change photo button
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 14, color: _kDark),
                    SizedBox(width: 6),
                    Text(
                      'Alterar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Empty state — add photo button
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder, width: 1.5),
          color: _kBg,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: _kBlue, size: 32),
            SizedBox(height: 8),
            Text(
              'Tirar ou escolher foto',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kBlue,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'JPEG, PNG ou WebP — máx. 10 MB',
              style: TextStyle(fontSize: 11, color: _kGray),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: _kBlue, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kDark,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: _kGray, size: 20),
          ],
        ),
      ),
    );
  }
}

class _OperatingHoursChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OperatingHoursChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _kBlue.withValues(alpha: 0.08) : _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _kBlue : _kBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? _kBlue : _kGray,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? _kBlue : _kDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomScheduleWidget extends StatelessWidget {
  final Map<int, Map<String, String>> customSchedule;

  const _CustomScheduleWidget({required this.customSchedule});

  static const _days = {
    1: 'Segunda',
    2: 'Terça',
    3: 'Quarta',
    4: 'Quinta',
    5: 'Sexta',
    6: 'Sábado',
    7: 'Domingo',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: _days.entries.map((entry) {
          final day = entry.key;
          final name = entry.value;
          final isOpen = customSchedule.containsKey(day);
          final openTime = isOpen ? customSchedule[day]!['open']! : '08:00';
          final closeTime = isOpen ? customSchedule[day]!['close']! : '18:00';

          return _DayRow(
            day: day,
            name: name,
            isOpen: isOpen,
            openTime: openTime,
            closeTime: closeTime,
            isLast: day == 7,
          );
        }).toList(),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final int day;
  final String name;
  final bool isOpen;
  final String openTime;
  final String closeTime;
  final bool isLast;

  const _DayRow({
    required this.day,
    required this.name,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
    required this.isLast,
  });

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    if (!isOpen) return;

    final initialTimeStr = isStart ? openTime : closeTime;
    final initialParts = initialTimeStr.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(initialParts[0]) ?? 8,
      minute: int.tryParse(initialParts[1]) ?? 0,
    );

    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (selected != null) {
      final hour = selected.hour.toString().padLeft(2, '0');
      final minute = selected.minute.toString().padLeft(2, '0');
      final newTime = '$hour:$minute';

      if (context.mounted) {
        context.read<AddBathroomBloc>().add(UpdateDayTimeEvent(
              day,
              isStart ? newTime : openTime,
              isStart ? closeTime : newTime,
            ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: isOpen,
              activeColor: _kBlue,
              onChanged: (val) {
                if (val != null) {
                  context.read<AddBathroomBloc>().add(ToggleDayEvent(day, val));
                }
              },
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isOpen ? _kDark : _kGray,
              ),
            ),
          ),
          const Spacer(),
          _TimeButton(
            time: openTime,
            isEnabled: isOpen,
            onTap: () => _selectTime(context, true),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('-', style: TextStyle(color: _kGray)),
          ),
          _TimeButton(
            time: closeTime,
            isEnabled: isOpen,
            onTap: () => _selectTime(context, false),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String time;
  final bool isEnabled;
  final VoidCallback onTap;

  const _TimeButton({
    required this.time,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : _kBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? _kBorder : Colors.transparent,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isEnabled ? _kDark : _kGray.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
