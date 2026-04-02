import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';

class OnboardingTimePickerCard extends StatelessWidget {
  const OnboardingTimePickerCard({
    required this.label,
    required this.time,
    required this.onTap,
    super.key,
  });

  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingXL),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                time,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
