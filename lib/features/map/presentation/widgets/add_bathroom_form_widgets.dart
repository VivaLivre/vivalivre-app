import 'dart:io';
import 'package:flutter/material.dart';
import 'add_bathroom_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';


class CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.sheetBg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: context.textDark, size: 20),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kAddBathroomBlue),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textDark,
          ),
        ),
      ],
    );
  }
}

class ToggleRow extends StatelessWidget {
  final String icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleRow({
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
            style: TextStyle(fontSize: 15, color: context.textDark),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: kAddBathroomBlue,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD1D5DB),
          ),
        ],
      ),
    );
  }
}

class PhotoPicker extends StatelessWidget {
  final XFile? photo;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const PhotoPicker({
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
                  color: context.sheetBg.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 14, color: context.textDark),
                    SizedBox(width: 6),
                    Text(
                      'Alterar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textDark,
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
          border: Border.all(color: context.border, width: 1.5),
          color: context.bg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: kAddBathroomBlue, size: 32),
            SizedBox(height: 8),
            Text(
              'Tirar ou escolher foto',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kAddBathroomBlue,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'JPEG, PNG ou WebP — máx. 10 MB',
              style: TextStyle(fontSize: 11, color: context.textGray),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PhotoOptionTile({
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
          color: context.bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: kAddBathroomBlue, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textDark,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: context.textGray, size: 20),
          ],
        ),
      ),
    );
  }
}
