import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';

class FlashcardProgressBar extends StatelessWidget {
  const FlashcardProgressBar({
    required this.current,
    required this.total,
    super.key,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = total > 0 ? current / total : 0.0;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Text(
          '$current / $total',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
