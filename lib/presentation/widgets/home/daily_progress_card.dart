import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/theme/app_colors.dart';
import 'package:til1m/presentation/blocs/home/home_cubit.dart';

class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({required this.data, super.key});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final progress = data.dailyGoal > 0
        ? (data.todayReviewed / data.dailyGoal).clamp(0.0, 1.0)
        : 0.0;
    final isGoalReached = data.todayReviewed >= data.dailyGoal;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKeys.homeDailyGoal.tr(context: context),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusFull,
                    ),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: colorScheme.outline.withValues(
                        alpha: 0.25,
                      ),
                      color: isGoalReached
                          ? AppColors.successLight
                          : colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(
                    isGoalReached
                        ? LocaleKeys.homeGoalReached.tr(context: context)
                        : LocaleKeys.homeWordsDone.tr(
                            namedArgs: {
                              'done': '${data.todayReviewed}',
                              'total': '${data.dailyGoal}',
                            },
                          ),
                    style: textTheme.bodySmall?.copyWith(
                      color: isGoalReached
                          ? AppColors.successLight
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isGoalReached
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.paddingL),
            Column(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: data.streakDays > 0
                      ? (isDark
                            ? AppColors.warningDark
                            : AppColors.warningLight)
                      : colorScheme.outline,
                  size: 28,
                ),
                const SizedBox(height: 2),
                Text(
                  '${data.streakDays}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  LocaleKeys.homeStreak.tr(context: context),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
