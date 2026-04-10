import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/theme/app_colors.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/entities/word_progress.dart';

class FlashcardFrontFace extends StatelessWidget {
  const FlashcardFrontFace({
    required this.word,
    required this.progress,
    required this.isCurrentReview,
    required this.isAudioPlaying,
    required this.onFlip,
    required this.onAudio,
    super.key,
  });

  final Word word;
  final WordProgress progress;
  final bool isCurrentReview;
  final bool isAudioPlaying;
  final VoidCallback onFlip;
  final VoidCallback onAudio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final levelColor = AppColors.level[word.level.label] ?? colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark
        ? AppColors.successDark
        : AppColors.successLight;

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusXXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (word.imageUrl != null)
              Expanded(
                flex: 3,
                child: CachedNetworkImage(
                  imageUrl: word.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => ColoredBox(
                    color: colorScheme.surfaceContainerHigh,
                    child: Center(
                      child: Icon(
                        Icons.image_rounded,
                        size: 40,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => ColoredBox(
                    color: colorScheme.surfaceContainerHigh,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 40,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                flex: 2,
                child: ColoredBox(
                  color: colorScheme.surfaceContainerHigh,
                  child: Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 56,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ),
              ),

            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingXXL,
                  AppConstants.paddingL,
                  AppConstants.paddingXXL,
                  AppConstants.paddingL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _LevelBadge(
                          label: word.level.label,
                          color: levelColor,
                        ),
                        _TypeBadge(
                          isReview: isCurrentReview,
                          successColor: successColor,
                        ),
                      ],
                    ),
                    const Spacer(),

                    Text(
                      word.word,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    if (word.transcriptionText != null) ...[
                      const SizedBox(height: AppConstants.paddingXS),
                      Text(
                        '[${word.transcriptionText}]',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],

                    const SizedBox(height: AppConstants.paddingM),
                    Center(
                      child: IconButton.filledTonal(
                        onPressed: isAudioPlaying ? null : onAudio,
                        icon: isAudioPlaying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.volume_up_rounded),
                        tooltip: LocaleKeys.wordAudioPlay.tr(context: context),
                      ),
                    ),

                    const Spacer(),

                    const Divider(height: 1),
                    const SizedBox(height: AppConstants.paddingM),
                    FilledButton(
                      onPressed: onFlip,
                      child: Text(LocaleKeys.wordBtnFlip.tr(context: context)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
  const _TypeBadge({required this.isReview, required this.successColor});

  final bool isReview;
  final Color successColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isReview ? colorScheme.secondary : successColor;
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
