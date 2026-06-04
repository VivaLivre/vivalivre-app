import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class Bathroom extends Equatable {
  final int id;
  final String name;
  final LatLng location;
  final double rating;
  final List<String> tags;
  final String? address;
  final bool isAccessible;
  final bool hasChangingTable;
  final bool isFree;
  final double cleanlinessRating;
  final double accessibilityRating;
  final String? photoUrl;
  final Map<String, dynamic> operatingHours;
  final String? observations;

  const Bathroom({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.tags,
    this.address,
    this.isAccessible = false,
    this.hasChangingTable = false,
    this.isFree = false,
    this.cleanlinessRating = 0.0,
    this.accessibilityRating = 0.0,
    this.photoUrl,
    this.operatingHours = const {'type': 'unknown'},
    this.observations,
  });

  /// Business rule: determines if the bathroom is currently open.
  ///
  /// - `unknown` → considered open (benefit of the doubt).
  /// - `24h` → always open.
  /// - `custom` → checks current weekday and time against the schedule.
  bool get isOpen {
    final type = operatingHours['type'] as String? ?? 'unknown';

    if (type == 'unknown' || type == '24h') return true;

    if (type == 'custom') {
      final schedule = operatingHours['schedule'] as Map<String, dynamic>?;
      if (schedule == null) return true;

      final now = DateTime.now();
      // DateTime.weekday: 1 = Monday, 7 = Sunday
      final dayKey = now.weekday.toString();
      final daySchedule = schedule[dayKey] as Map<String, dynamic>?;

      if (daySchedule == null) return false; // No schedule for today → closed

      final openStr = daySchedule['open'] as String?;
      final closeStr = daySchedule['close'] as String?;

      if (openStr == null || closeStr == null) return false;

      final openParts = openStr.split(':');
      final closeParts = closeStr.split(':');

      if (openParts.length < 2 || closeParts.length < 2) return false;

      final openMinutes =
          int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      final closeMinutes =
          int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
      final nowMinutes = now.hour * 60 + now.minute;

      if (openMinutes < closeMinutes) {
        return nowMinutes >= openMinutes && nowMinutes < closeMinutes;
      } else {
        // Horário passa da meia-noite (ex: 22:00 às 06:00)
        return nowMinutes >= openMinutes || nowMinutes < closeMinutes;
      }
    }

    return true; // Fallback: consider open
  }

  @override
  List<Object?> get props => [
        id,
        name,
        location,
        rating,
        tags,
        address,
        isAccessible,
        hasChangingTable,
        isFree,
        cleanlinessRating,
        accessibilityRating,
        photoUrl,
        operatingHours,
        observations,
      ];
}
