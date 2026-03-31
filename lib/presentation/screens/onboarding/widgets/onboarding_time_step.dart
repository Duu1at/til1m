import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wordup/core/constants/locale_keys.dart';

class OnboardingTimeStep extends StatelessWidget {
  const OnboardingTimeStep({
    required this.from,
    required this.to,
    required this.onFromChanged,
    required this.onToChanged,
    super.key,
  });

  final TimeOfDay from;
  final TimeOfDay to;
  final ValueChanged<TimeOfDay> onFromChanged;
  final ValueChanged<TimeOfDay> onToChanged;

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onChanged,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  static String _fmt(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.onboardingStepTime.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            LocaleKeys.onboardingStepTimeSubtitle.tr(),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: _TimePickerCard(
                  label: LocaleKeys.onboardingTimeFrom.tr(),
                  time: _fmt(from),
                  onTap: () => _pickTime(context, from, onFromChanged),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TimePickerCard(
                  label: LocaleKeys.onboardingTimeTo.tr(),
                  time: _fmt(to),
                  onTap: () => _pickTime(context, to, onToChanged),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Icon(
              Icons.notifications_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  const _TimePickerCard({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
