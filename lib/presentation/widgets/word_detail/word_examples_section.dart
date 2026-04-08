import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/domain/entities/word.dart';

class WordExamplesSection extends StatelessWidget {
  const WordExamplesSection({
    required this.examples,
    required this.lang,
    super.key,
  });

  final List<WordExample> examples;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.wordExamples.tr(context: context),
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppConstants.paddingM),
        ...examples.take(3).map(
              (e) => _ExampleCard(example: e, lang: lang),
            ),
      ],
    );
  }
}

final class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.example, required this.lang});

  final WordExample example;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final translation = lang == 'ru' ? example.exampleRu : example.exampleKy;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border(
            left: BorderSide(color: colorScheme.primary, width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                example.exampleEn,
                style: textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (translation != null) ...[
                const SizedBox(height: AppConstants.paddingS),
                Text(
                  translation,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
