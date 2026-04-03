import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/presentation/presentation.dart';

class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatisticsCubit, StatisticsState>(
      builder: (context, state) {
        final data = state is StatisticsLoaded
            ? state.data
            : StatisticsData.empty;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingM,
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: StatCell(
                      value: '${data.knownCount}',
                      label: LocaleKeys.dictionaryFilterKnown.tr(),
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: AppConstants.dividerThickness,
                    color: Theme.of(context).dividerColor,
                  ),
                  Expanded(
                    child: StatCell(
                      value: '${data.learningCount}',
                      label: LocaleKeys.dictionaryFilterLearning.tr(),
                      icon: Icons.school_outlined,
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: AppConstants.dividerThickness,
                    color: Theme.of(context).dividerColor,
                  ),
                  Expanded(
                    child: StatCell(
                      value: '${data.todayReviewed}',
                      label: LocaleKeys.homeReviewToday.tr(),
                      icon: Icons.today_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
