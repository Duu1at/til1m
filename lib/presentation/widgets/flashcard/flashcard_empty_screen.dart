import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/presentation/blocs/flashcard/flashcard_bloc.dart';

class FlashcardEmptyScreen extends StatelessWidget {
  const FlashcardEmptyScreen({
    required this.source,
    required this.onLoadMore,
    super.key,
  });

  final FlashcardSource source;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (icon, title, subtitle, showLoadMore) = switch (source) {
      FlashcardSource.review => (
          Icons.done_all_rounded,
          'Нет слов на повторение',
          'Все слова повторены. Ты молодец!',
          true,
        ),
      FlashcardSource.newWords => (
          Icons.auto_awesome_rounded,
          'Новых слов нет',
          'Все слова на этом уровне уже добавлены',
          false,
        ),
      FlashcardSource.mixed => (
          Icons.check_circle_outline_rounded,
          'Все слова на сегодня пройдены',
          'Приходи завтра или загрузи дополнительные слова',
          true,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSection),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Icon(
                icon,
                size: 80,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppConstants.paddingXXL),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (showLoadMore) ...[
              const SizedBox(height: AppConstants.paddingSection),
              SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: FilledButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Учить новые слова'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
