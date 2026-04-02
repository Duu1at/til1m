import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';

class OnboardingGoalCustomOption extends StatelessWidget {
  const OnboardingGoalCustomOption({
    required this.isSelected,
    required this.controller,
    required this.onTap,
    required this.onChanged,
    super.key,
  });

  final bool isSelected;
  final TextEditingController controller;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.paddingS / 2,
          horizontal: AppConstants.paddingXL,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              LocaleKeys.onboardingGoalCustom.tr(context: context),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            if (isSelected)
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: LocaleKeys.onboardingGoalCustomHint.tr(context: context),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
