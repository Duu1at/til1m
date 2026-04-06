import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/theme/app_colors.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/presentation/blocs/flashcards/flashcards_bloc.dart';

class FlashcardFront extends StatelessWidget {
  const FlashcardFront({required this.item, super.key});

  final FlashcardItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final levelColor =
        AppColors.level[item.word.level.label] ?? colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusXXL),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top row: level badge + review/new badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LevelBadge(
                  label: item.word.level.label,
                  color: levelColor,
                ),
                _TypeBadge(isReview: item.isReview),
              ],
            ),

            // Word — vertically centered
            const Spacer(),
            Text(
              item.word.word,
              textAlign: TextAlign.center,
              style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            if (item.word.transcriptionText != null) ...[
              const SizedBox(height: AppConstants.paddingS),
              Text(
                '[${item.word.transcriptionText}]',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ],
            const SizedBox(height: AppConstants.paddingM),
            Text(
              _partOfSpeechLabel(context, item),
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),

            // Tap hint
            const Divider(height: 1),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppConstants.paddingXS),
                Text(
                  LocaleKeys.wordBtnFlip.tr(context: context),
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _partOfSpeechLabel(BuildContext context, FlashcardItem item) {
    return switch (item.word.partOfSpeech.name) {
      'noun' => LocaleKeys.wordPosNoun.tr(context: context),
      'verb' => LocaleKeys.wordPosVerb.tr(context: context),
      'adjective' => LocaleKeys.wordPosAdjective.tr(context: context),
      'adverb' => LocaleKeys.wordPosAdverb.tr(context: context),
      'phrase' => LocaleKeys.wordPosPhrase.tr(context: context),
      _ => item.word.partOfSpeech.name,
    };
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingXS,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.isReview});

  final bool isReview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isReview
        ? colorScheme.secondary
        : colorScheme.tertiary;
    final icon = isReview ? Icons.refresh_rounded : Icons.star_rounded;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingS,
          vertical: AppConstants.paddingXS,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
