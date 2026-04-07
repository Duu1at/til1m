import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';

class LangCard extends StatelessWidget {
  const LangCard({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final String flag;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingXL,
            vertical: AppConstants.paddingXL,
          ),
          child: Row(
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(width: AppConstants.paddingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
