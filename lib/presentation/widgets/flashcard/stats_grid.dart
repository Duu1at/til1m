import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({
    required this.totalAnswered,
    required this.correctCount,
    required this.accuracyPercent,
    required this.newWordsLearned,
    required this.wordsReviewed,
    required this.durationLabel,
    required this.successColor,
    super.key,
  });

  final int totalAnswered;
  final int correctCount;
  final int accuracyPercent;
  final int newWordsLearned;
  final int wordsReviewed;
  final String durationLabel;
  final Color successColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusXXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Изучено',
                    value: '$totalAnswered',
                    icon: Icons.school_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Правильно',
                    value: '$correctCount ($accuracyPercent%)',
                    icon: Icons.check_circle_rounded,
                    color: successColor,
                  ),
                ),
              ],
            ),
            const Divider(height: AppConstants.paddingXXL),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Новых слов',
                    value: '$newWordsLearned',
                    icon: Icons.star_rounded,
                    color: colorScheme.tertiary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Повторено',
                    value: '$wordsReviewed',
                    icon: Icons.refresh_rounded,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const Divider(height: AppConstants.paddingXXL),
            _StatItem(
              label: 'Время сессии',
              value: durationLabel,
              icon: Icons.timer_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppConstants.paddingS),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
