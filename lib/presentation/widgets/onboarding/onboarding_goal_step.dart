import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wordup/core/constants/app_constants.dart';
import 'package:wordup/core/constants/locale_keys.dart';
import 'package:wordup/presentation/presentation.dart';

class OnboardingGoalStep extends StatelessWidget {
  const OnboardingGoalStep({
    required this.selected,
    required this.isCustom,
    required this.controller,
    required this.onSelect,
    required this.onCustomTap,
    required this.onCustomChanged,
    super.key,
  });

  final int? selected;
  final bool isCustom;
  final TextEditingController controller;
  final ValueChanged<int> onSelect;
  final VoidCallback onCustomTap;
  final ValueChanged<String> onCustomChanged;

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
            LocaleKeys.onboardingStepGoal.tr(context: context),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Text(
            LocaleKeys.onboardingStepGoalSubtitle.tr(context: context),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSection),
          ...AppConstants.dailyGoalOptions.map((count) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
              child: OnboardingGoalOption(
                label: LocaleKeys.onboardingGoalWords.tr(
                  context: context,
                  namedArgs: {'count': '$count'},
                ),
                isSelected: !isCustom && selected == count,
                onTap: () => onSelect(count),
              ),
            );
          }),
          OnboardingGoalCustomOption(
            isSelected: isCustom,
            controller: controller,
            onTap: onCustomTap,
            onChanged: onCustomChanged,
          ),
        ],
      ),
    );
  }
}
