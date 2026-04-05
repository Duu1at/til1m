import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/theme/app_colors.dart';
import 'package:til1m/domain/entities/user_progress.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/presentation/blocs/blocs.dart';

class WordListTile extends StatelessWidget {
  const WordListTile({
    required this.item,
    required this.lang,
    super.key,
  });

  final WordWithStatus item;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final word = item.word;
    final translation =
        word.translationFor(lang) ?? word.translationFor('ru') ?? '';
    final levelText = word.level.label;
    final levelColor = AppColors.level[levelText] ?? AppColors.indigo500;

    return InkWell(
      onTap: () => context.push('/word/${word.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingM,
        ),
        child: Row(
          children: [
            // Status dot
            _StatusDot(status: item.status),
            const SizedBox(width: AppConstants.paddingM),
            // Word info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          word.word,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      _LevelChip(text: levelText, color: levelColor),
                      const SizedBox(width: AppConstants.paddingXS),
                      _PosLabel(pos: word.partOfSpeech, lang: lang),
                    ],
                  ),
                  if (translation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      translation,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppConstants.paddingS),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

final class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final WordStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      WordStatus.known => AppColors.successLight,
      WordStatus.learning => colorScheme.primary,
      WordStatus.newWord => colorScheme.outlineVariant,
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const SizedBox(width: 8, height: 8),
    );
  }
}

final class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXS,
          vertical: 2,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

final class _PosLabel extends StatelessWidget {
  const _PosLabel({required this.pos, required this.lang});

  final PartOfSpeech pos;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final label = _posShort(pos, lang);
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  static String _posShort(PartOfSpeech pos, String lang) {
    if (lang == 'ky') {
      return switch (pos) {
        PartOfSpeech.noun => 'зат ат.',
        PartOfSpeech.verb => 'этиш',
        PartOfSpeech.adjective => 'сын ат.',
        PartOfSpeech.adverb => 'тактооч',
        PartOfSpeech.phrase => 'фраза',
      };
    }
    return switch (pos) {
      PartOfSpeech.noun => 'сущ.',
      PartOfSpeech.verb => 'глаг.',
      PartOfSpeech.adjective => 'прил.',
      PartOfSpeech.adverb => 'нар.',
      PartOfSpeech.phrase => 'фраза',
    };
  }
}
