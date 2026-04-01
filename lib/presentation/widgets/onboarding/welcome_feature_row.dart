import 'package:flutter/material.dart';
import 'package:wordup/core/constants/app_constants.dart';

class WelcomeFeatureRow extends StatelessWidget {
  const WelcomeFeatureRow({
    required this.icon,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: SizedBox.square(
            dimension: AppConstants.iconBoxSize,
            child: Center(
              child: Icon(
                Icons.check_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingL),
        Expanded(
          child: Text(text, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
