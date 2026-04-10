import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';

class FlashcardProgressBar extends StatelessWidget {
  const FlashcardProgressBar({
    required this.current,
    required this.total,
    this.reviewCount = 0,
    this.newCount = 0,
    super.key,
  });

  final int current;
  final int total;
  final int reviewCount;
  final int newCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$current',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              ' / $total',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (reviewCount > 0)
              _MiniChip(
                label: '↻ $reviewCount',
                color: colorScheme.secondary,
              ),
            if (reviewCount > 0 && newCount > 0)
              const SizedBox(width: AppConstants.paddingXS),
            if (newCount > 0)
              _MiniChip(
                label: '★ $newCount',
                color: colorScheme.tertiary,
              ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingXS),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: AppConstants.durationNormal,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingS,
          vertical: 2,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
