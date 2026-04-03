import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/domain/entities/word.dart';

class LevelProgressRow extends StatelessWidget {
  const LevelProgressRow({
    required this.level,
    required this.known,
    super.key,
  });

  final WordLevel level;
  final int known;

  static const Map<WordLevel, Color> _levelColors = {
    WordLevel.a1: Color(0xFF22C55E),
    WordLevel.a2: Color(0xFF84CC16),
    WordLevel.b1: Color(0xFFF59E0B),
    WordLevel.b2: Color(0xFFEF4444),
    WordLevel.c1: Color(0xFFA855F7),
    WordLevel.c2: Color(0xFF0EA5E9),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _levelColors[level] ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingXS),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              level.name.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              child: LinearProgressIndicator(
                value: 0,
                backgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.08,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          SizedBox(
            width: 28,
            child: Text(
              '0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
