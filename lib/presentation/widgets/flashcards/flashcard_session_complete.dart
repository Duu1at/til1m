import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/theme/app_colors.dart';
import 'package:til1m/presentation/blocs/flashcards/flashcards_bloc.dart';

class FlashcardSessionComplete extends StatelessWidget {
  const FlashcardSessionComplete({
    required this.stats,
    required this.onRestart,
    required this.onFinish,
    super.key,
  });

  final FlashcardsSessionStats stats;
  final VoidCallback onRestart;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final successColor =
        isDark ? AppColors.successDark : AppColors.successLight;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXXL,
          vertical: AppConstants.paddingSection,
        ),
        child: Column(
          children: [
            const Spacer(),

            // Trophy icon
            Icon(
              Icons.emoji_events_rounded,
              size: 80,
              color: isDark ? AppColors.warningDark : AppColors.warningLight,
            ),
            const SizedBox(height: AppConstants.paddingXXL),

            Text(
              LocaleKeys.flashcardsSessionDone.tr(context: context),
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSection),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCell(
                  label: LocaleKeys.wordBtnKnow.tr(context: context),
                  value: '${stats.knew}',
                  color: successColor,
                ),
                _Divider(),
                _StatCell(
                  label: LocaleKeys.wordBtnDontKnow.tr(context: context),
                  value: '${stats.didntKnow}',
                  color: colorScheme.error,
                ),
                _Divider(),
                _StatCell(
                  label: LocaleKeys.flashcardsAccuracy.tr(
                    context: context,
                    namedArgs: {'percent': ''},
                  ).replaceAll(': %', ''),
                  value: '${stats.accuracyPercent}%',
                  color: colorScheme.primary,
                ),
              ],
            ),

            const Spacer(),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: FilledButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  LocaleKeys.flashcardsBtnRestart.tr(context: context),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: OutlinedButton(
                onPressed: onFinish,
                child: Text(
                  LocaleKeys.flashcardsBtnFinish.tr(context: context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: VerticalDivider(
        color: Theme.of(
          context,
        ).colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
  }
}
