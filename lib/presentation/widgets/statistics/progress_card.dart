import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/presentation/presentation.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({required this.data, super.key});

  final StatisticsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            theme.cardTheme.color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.statisticsProgressByLevel.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            ...WordLevel.values.map(
              (level) => LevelProgressRow(
                level: level,
                known: data.knownCount,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: AppConstants.paddingXS),
                Expanded(
                  child: Text(
                    '${LocaleKeys.dictionaryFilterLearning.tr()}: ${data.learningCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
