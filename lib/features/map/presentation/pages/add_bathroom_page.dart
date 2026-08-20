// ─────────────────────────────────────────────────────────────────────────────
// add_bathroom_page.dart — VivaLivre
// Uber-style bathroom suggestion page with fixed center pin
// ─────────────────────────────────────────────────────────────────────────────


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:viva_livre_app/features/map/presentation/bloc/add_bathroom_bloc.dart';
import '../widgets/add_bathroom_form_widgets.dart';
import '../widgets/add_bathroom_schedule_widgets.dart';
import '../widgets/add_bathroom_theme.dart';




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
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.sheetBg,
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
                color: context.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Adicionar Foto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textDark,
              ),
            ),
            const SizedBox(height: 20),
            PhotoOptionTile(
              icon: Icons.camera_alt_rounded,
              label: 'Tirar Foto',
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            const SizedBox(height: 12),
            PhotoOptionTile(
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
                        'Será analisada pela equipe.'),
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
          showModalBottomSheet(
            context: context,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            builder: (context) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 40),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Oops! Algo correu mal',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Entendido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
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
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        context.isDark
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        BlendMode.color,
                      ),
                      child: TileLayer(
                        urlTemplate: context.isDark
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                            : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.vivalivre.app',
                        maxNativeZoom: 19,
                        maxZoom: 22,
                      ),
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
                                color: kAddBathroomBlue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        kAddBathroomBlue.withValues(alpha: 0.4 + lift * 0.2),
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
                                    kAddBathroomBlue.withValues(alpha: 0.3 - lift * 0.15),
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
                        context.sheetBg,
                        context.sheetBg.withValues(alpha: 0.95),
                        context.sheetBg.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.7, 1.0],
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sugerir Banheiro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.textDark,
                          ),
                        ),
                      ),
                      // Crosshair / re-center button
                      CircleButton(
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
                      color: context.sheetBg,
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
                              color: kAddBathroomBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'A procurar endereço...',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.location_on_rounded,
                              color: kAddBathroomBlue, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              state.address.isNotEmpty
                                  ? state.address
                                  : 'Mova o mapa para selecionar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.textDark,
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
                      color: context.sheetBg,
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
                              color: context.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // ── Address Field (editable) ──
                        const SectionLabel(
                            icon: Icons.pin_drop_rounded,
                            label: 'Endereço'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _addressController,
                          onChanged: (val) => context
                              .read<AddBathroomBloc>()
                              .add(AddressEdited(val)),
                          style: TextStyle(fontSize: 14, color: context.textDark),
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
                                        color: kAddBathroomBlue,
                                      ),
                                    ),
                                  )
                                : Icon(Icons.edit_rounded,
                                    size: 18, color: context.textGray),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Name Field ──
                        const SectionLabel(
                            icon: Icons.storefront_rounded,
                            label: 'Nome do Local'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: TextStyle(fontSize: 14, color: context.textDark),
                          decoration: _inputDecoration(
                            hint: 'Ex: Shopping ABCD, Posto Shell...',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Photo Section ──
                        const SectionLabel(
                            icon: Icons.camera_alt_rounded,
                            label: 'Foto do Local'),
                        const SizedBox(height: 4),
                        Text(
                          'Obrigatória. O ideal é uma foto da frente do banheiro, mas também pode ser uma foto da fachada do estabelecimento.',
                          style: TextStyle(fontSize: 12, color: context.textGray, height: 1.3),
                        ),
                        const SizedBox(height: 10),
                        PhotoPicker(
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
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              ToggleRow(
                                icon: '♿',
                                label: 'Acessível para PCD',
                                value: state.isAccessible,
                                onChanged: (_) => context
                                    .read<AddBathroomBloc>()
                                    .add(const ToggleAccessible()),
                              ),
                              Divider(height: 1, color: context.border),
                              ToggleRow(
                                icon: '🍼',
                                label: 'Possui Trocador',
                                value: state.hasChangingTable,
                                onChanged: (_) => context
                                    .read<AddBathroomBloc>()
                                    .add(const ToggleChangingTable()),
                              ),
                              Divider(height: 1, color: context.border),
                              ToggleRow(
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
                        const SectionLabel(
                            icon: Icons.schedule_rounded,
                            label: 'Horário de Funcionamento'),
                        const SizedBox(height: 4),
                        Text(
                          'Selecione o tipo de horário',
                          style: TextStyle(fontSize: 12, color: context.textGray),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OperatingHoursChip(
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
                              child: OperatingHoursChip(
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
                        OperatingHoursChip(
                          label: 'Personalizado',
                          icon: Icons.edit_calendar_rounded,
                          isSelected: state.operatingHoursType == 'custom',
                          onTap: () => context
                              .read<AddBathroomBloc>()
                              .add(const SelectOperatingHours('custom')),
                        ),
                        if (state.operatingHoursType == 'custom') ...[
                          const SizedBox(height: 16),
                          CustomScheduleWidget(
                              customSchedule: state.customSchedule),
                        ],
                        const SizedBox(height: 24),

                        // ── Comment ──
                        Row(
                          children: [
                            const SectionLabel(
                                icon: Icons.comment_rounded,
                                label: 'Comentário'),
                            const SizedBox(width: 6),
                            Text(
                              '(opcional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textGray.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          style: TextStyle(fontSize: 14, color: context.textDark),
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
                              backgroundColor: kAddBathroomBlue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  kAddBathroomBlue.withValues(alpha: 0.6),
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
      hintStyle: TextStyle(color: context.textGray, fontSize: 14),
      filled: true,
      fillColor: context.bg,
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kAddBathroomBlue, width: 2),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════════
