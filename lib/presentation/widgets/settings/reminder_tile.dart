import 'dart:async' show unawaited;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/presentation/presentation.dart';

class ReminderTile extends StatelessWidget {
  const ReminderTile({required this.currentTime, super.key});

  final String? currentTime;

  @override
  Widget build(BuildContext context) {
    final isEnabled = currentTime != null && currentTime!.isNotEmpty;

    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingXXL,
          ),
          title: Text(LocaleKeys.settingsReminder.tr(context: context)),
          subtitle: Text(
            isEnabled
                ? currentTime!
                : LocaleKeys.settingsReminderOff.tr(context: context),
          ),
          value: isEnabled,
          onChanged: (value) => unawaited(_handleToggle(context, value)),
        ),
        if (isEnabled)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingXXL,
            ),
            leading: const Icon(Icons.access_time),
            title: Text(currentTime!),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () => unawaited(_pickTime(context)),
          ),
      ],
    );
  }

  Future<void> _handleToggle(BuildContext context, bool value) async {
    if (value) {
      await _pickTime(context);
    } else {
      await context.read<SettingsCubit>().updateReminderTime(null);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final initial =
        _parseTime(currentTime) ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && context.mounted) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await context.read<SettingsCubit>().updateReminderTime(formatted);
    }
  }

  TimeOfDay? _parseTime(String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
