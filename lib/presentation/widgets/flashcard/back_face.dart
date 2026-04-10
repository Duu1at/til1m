import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/theme/app_colors.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/presentation/widgets/flashcard/level_badge.dart';
import 'package:til1m/presentation/widgets/flashcard/pos_badge.dart';

class BackFace extends StatelessWidget {
  const BackFace({
    required this.word,
    required this.onKnow,
    required this.onDontKnow,
    super.key,
  });

  final Word word;
  final VoidCallback onKnow;
  final VoidCallback onDontKnow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final lang = context.locale.languageCode;
    final translation =
        word.translationFor(lang) ?? word.translationFor('ru') ?? '—';
    final levelColor = AppColors.level[word.level.label] ?? colorScheme.primary;
    final successColor = isDark
        ? AppColors.successDark
        : AppColors.successLight;

    final synonyms = word.translations
        .where((t) => t.language.name == lang)
        .expand((t) => t.synonyms)
        .take(3)
        .toList();

    final examples = word.examples.take(3).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusXXL),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
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
            Row(
              children: [
                LevelBadge(label: word.level.label, color: levelColor),
                const SizedBox(width: AppConstants.paddingS),
                PosBadge(label: word.partOfSpeech.name),
              ],
            ),
            const Spacer(),

            Text(
              word.word,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),

            Text(
              translation,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),

            if (synonyms.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingXS),
              Text(
                synonyms.join(', '),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            if (examples.isNotEmpty) ...[
              const Spacer(),
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
              ...examples.map(
                (ex) => Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.paddingS),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.exampleEn,
                        style: textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (_exampleTranslation(ex, lang) != null)
                        Text(
                          _exampleTranslation(ex, lang)!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ] else
              const Spacer(),

            const SizedBox(height: AppConstants.paddingM),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppConstants.buttonHeight,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(
                          color: colorScheme.error.withValues(alpha: 0.5),
                        ),
                      ),
                      onPressed: onDontKnow,
                      icon: const Icon(Icons.close_rounded),
                      label: Text(
                        LocaleKeys.wordBtnDontKnow.tr(context: context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: SizedBox(
                    height: AppConstants.buttonHeight,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: successColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onKnow,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        LocaleKeys.wordBtnKnow.tr(context: context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _exampleTranslation(WordExample ex, String lang) =>
      lang == 'ky' ? ex.exampleKy : ex.exampleRu;
}
