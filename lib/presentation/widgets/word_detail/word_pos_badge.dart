import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/domain/entities/word.dart';

class WordPosBadge extends StatelessWidget {
  const WordPosBadge({required this.pos, super.key});

  final PartOfSpeech pos;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingXS,
        ),
        child: Text(
          _posKey(pos).tr(context: context),
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _posKey(PartOfSpeech pos) => switch (pos) {
        PartOfSpeech.noun => LocaleKeys.wordPosNoun,
        PartOfSpeech.verb => LocaleKeys.wordPosVerb,
        PartOfSpeech.adjective => LocaleKeys.wordPosAdjective,
        PartOfSpeech.adverb => LocaleKeys.wordPosAdverb,
        PartOfSpeech.phrase => LocaleKeys.wordPosPhrase,
      };
}
