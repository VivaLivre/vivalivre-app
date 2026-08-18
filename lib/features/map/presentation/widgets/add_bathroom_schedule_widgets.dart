import 'package:flutter/material.dart';
import 'add_bathroom_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viva_livre_app/features/map/presentation/bloc/add_bathroom_bloc.dart';


class OperatingHoursChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const OperatingHoursChip({
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
          color: isSelected ? kAddBathroomBlue.withValues(alpha: 0.08) : context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kAddBathroomBlue : context.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? kAddBathroomBlue : context.textGray,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? kAddBathroomBlue : context.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomScheduleWidget extends StatelessWidget {
  final Map<int, Map<String, String>> customSchedule;

  const CustomScheduleWidget({required this.customSchedule});

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
        color: context.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: _days.entries.map((entry) {
          final day = entry.key;
          final name = entry.value;
          final isOpen = customSchedule.containsKey(day);
          final openTime = isOpen ? customSchedule[day]!['open']! : '08:00';
          final closeTime = isOpen ? customSchedule[day]!['close']! : '18:00';

          return DayRow(
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

class DayRow extends StatelessWidget {
  final int day;
  final String name;
  final bool isOpen;
  final String openTime;
  final String closeTime;
  final bool isLast;

  const DayRow({
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
            : Border(bottom: BorderSide(color: context.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: isOpen,
              activeColor: kAddBathroomBlue,
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
                color: isOpen ? context.textDark : context.textGray,
              ),
            ),
          ),
          const Spacer(),
          TimeButton(
            time: openTime,
            isEnabled: isOpen,
            onTap: () => _selectTime(context, true),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('-', style: TextStyle(color: context.textGray)),
          ),
          TimeButton(
            time: closeTime,
            isEnabled: isOpen,
            onTap: () => _selectTime(context, false),
          ),
        ],
      ),
    );
  }
}

class TimeButton extends StatelessWidget {
  final String time;
  final bool isEnabled;
  final VoidCallback onTap;

  const TimeButton({
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
          color: isEnabled ? context.sheetBg : context.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? context.border : Colors.transparent,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isEnabled ? context.textDark : context.textGray.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}