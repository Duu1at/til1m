import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/presentation/blocs/word_detail/word_detail_cubit.dart';
import 'package:til1m/presentation/widgets/word_detail/word_examples_section.dart';
import 'package:til1m/presentation/widgets/word_detail/word_level_badge.dart';
import 'package:til1m/presentation/widgets/word_detail/word_pos_badge.dart';

class WordDetailBody extends StatelessWidget {
  const WordDetailBody({required this.state, super.key});

  final WordDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final word = state.word;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final lang = context.locale.languageCode;
    final translation = word.translationFor(lang);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingXXL,
        vertical: AppConstants.paddingXXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word title
          Text(
            word.word,
            style: textTheme.displaySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),

          Row(
            children: [
              WordPosBadge(pos: word.partOfSpeech),
              const SizedBox(width: AppConstants.paddingS),
              WordLevelBadge(level: word.level),
            ],
          ),
          const SizedBox(height: AppConstants.paddingL),

          if (word.transcriptionText != null || word.audioUrl != null)
            _TranscriptionRow(state: state),

          if (word.imageUrl != null) ...[
            const SizedBox(height: AppConstants.paddingL),
            _WordImage(imageUrl: word.imageUrl!),
          ],
          const SizedBox(height: AppConstants.paddingXXL),

          Text(
            translation ??
                LocaleKeys.wordUnknownTranslation.tr(context: context),
            style: textTheme.headlineSmall,
          ),

          if (word.examples.isNotEmpty) ...[
            const SizedBox(height: AppConstants.paddingXXL),
            WordExamplesSection(examples: word.examples, lang: lang),
          ],

          const SizedBox(height: AppConstants.paddingLarge),
        ],
      ),
    );
  }
}

final class _TranscriptionRow extends StatelessWidget {
  const _TranscriptionRow({required this.state});

  final WordDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final word = state.word;

    return Row(
      children: [
        if (word.transcriptionText != null)
          Expanded(
            child: Text(
              word.transcriptionText!,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (word.audioUrl != null)
          IconButton(
            icon: AnimatedSwitcher(
              duration: AppConstants.durationFast,
              child: state.isPlaying
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      key: const ValueKey('play'),
                      Icons.volume_up_rounded,
                      color: colorScheme.primary,
                    ),
            ),
            tooltip: LocaleKeys.wordAudioPlay.tr(context: context),
            onPressed: state.isPlaying
                ? null
                : () => context.read<WordDetailCubit>().playAudio(),
          ),
      ],
    );
  }
}

final class _WordImage extends StatelessWidget {
  const _WordImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusL),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, _) => ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: const SizedBox(height: 200, width: double.infinity),
        ),
        errorWidget: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
