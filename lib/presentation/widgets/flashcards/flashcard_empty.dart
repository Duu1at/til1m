import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';

class FlashcardEmpty extends StatelessWidget {
  const FlashcardEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSection),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 72,
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppConstants.paddingXXL),
            Text(
              LocaleKeys.homeNoWordsToday.tr(context: context),
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              LocaleKeys.homeGoalReached.tr(context: context),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
