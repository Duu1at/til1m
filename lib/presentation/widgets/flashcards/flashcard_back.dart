import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/theme/app_colors.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/presentation/blocs/flashcards/flashcards_bloc.dart';

class FlashcardBack extends StatelessWidget {
  const FlashcardBack({
    required this.item,
    required this.uiLanguage,
    super.key,
  });

  final FlashcardItem item;
  final String uiLanguage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final translation = item.word.translationFor(uiLanguage) ??
        item.word.translationFor('ru') ??
        LocaleKeys.wordUnknownTranslation.tr(context: context);

    final synonyms = item.word.translations
        .where((t) => t.language == uiLanguage)
        .expand((t) => t.synonyms)
        .take(3)
        .toList();

    final example =
        item.word.examples.isNotEmpty ? item.word.examples.first : null;

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
            // Level badge
            Align(
              alignment: Alignment.topLeft,
              child: _LevelBadge(
                label: item.word.level.label,
                color: levelColor,
              ),
            ),
            const Spacer(),

            // English word (smaller reminder)
            Text(
              item.word.word,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),

            // Translation — main focus
            Text(
              translation,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),

            // Synonyms
            if (synonyms.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingS),
              Text(
                synonyms.join(', '),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const Spacer(),

            // Example sentence
            if (example != null) ...[
              const Divider(height: 1),
              const SizedBox(height: AppConstants.paddingM),
              Text(
                LocaleKeys.wordExamples.tr(context: context),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.paddingXS),
              Text(
                example.exampleEn,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (_exampleTranslation(example) != null) ...[
                const SizedBox(height: 2),
                Text(
                  _exampleTranslation(example)!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String? _exampleTranslation(WordExample example) {
    if (uiLanguage == 'ky') return example.exampleKy;
    return example.exampleRu;
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
