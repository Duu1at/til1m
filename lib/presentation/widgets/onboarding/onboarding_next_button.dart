import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wordup/core/constants/app_constants.dart';
import 'package:wordup/core/constants/locale_keys.dart';

class OnboardingNextButton extends StatelessWidget {
  const OnboardingNextButton({
    required this.isLastStep,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final bool isLastStep;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingXXL,
        0,
        AppConstants.paddingXXL,
        AppConstants.paddingSection,
      ),
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor: theme.colorScheme.outlineVariant,
          disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          elevation: 0,
        ),
        child: Text(
          isLastStep
              ? LocaleKeys.onboardingBtnFinish.tr(context: context)
              : LocaleKeys.onboardingBtnNext.tr(context: context),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
