import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/presentation/presentation.dart';

class TopStatsRow extends StatelessWidget {
  const TopStatsRow({required this.data, super.key});

  final StatisticsData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.check_circle_outline,
            value: '${data.knownCount}',
            label: LocaleKeys.statisticsTotalKnown.tr(),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: StatCard(
            icon: Icons.local_fire_department_outlined,
            value: '${data.streakDays}',
            label: LocaleKeys.statisticsStreak.tr(),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: StatCard(
            icon: Icons.today_outlined,
            value: '${data.todayReviewed}',
            label: LocaleKeys.homeReviewToday.tr(),
          ),
        ),
      ],
    );
  }
}
