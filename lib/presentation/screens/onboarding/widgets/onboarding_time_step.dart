import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wordup/core/constants/app_constants.dart';
import 'package:wordup/core/constants/locale_keys.dart';
import 'package:wordup/presentation/presentation.dart';

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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingXXL,
        AppConstants.paddingSection,
        AppConstants.paddingXXL,
        AppConstants.paddingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.onboardingStepTime.tr(context: context),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Text(
            LocaleKeys.onboardingStepTimeSubtitle.tr(context: context),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.paddingHuge),
          Row(
            children: [
              Expanded(
                child: OnboardingTimePickerCard(
                  label: LocaleKeys.onboardingTimeFrom.tr(context: context),
                  time: _fmt(from),
                  onTap: () => _pickTime(context, from, onFromChanged),
                ),
              ),
              const SizedBox(width: AppConstants.paddingL),
              Expanded(
                child: OnboardingTimePickerCard(
                  label: LocaleKeys.onboardingTimeTo.tr(context: context),
                  time: _fmt(to),
                  onTap: () => _pickTime(context, to, onToChanged),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSection),
          Center(
            child: Icon(
              Icons.notifications_outlined,
              size: 64,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}
