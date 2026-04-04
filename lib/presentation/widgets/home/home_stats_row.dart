import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/theme/app_colors.dart';
import 'package:til1m/presentation/blocs/home/home_cubit.dart';

class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({required this.data, super.key});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.statisticsTitle.tr(context: context),
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.paddingM),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: LocaleKeys.homeStatKnown.tr(context: context),
                value: '${data.knownCount}',
                color: AppColors.successLight,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: _StatTile(
                label: LocaleKeys.homeStatLearning.tr(context: context),
                value: '${data.learningCount}',
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: _StatTile(
                label: LocaleKeys.homeStatTotal.tr(context: context),
                value: '${data.knownCount + data.learningCount}',
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.paddingM,
          horizontal: AppConstants.paddingS,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
