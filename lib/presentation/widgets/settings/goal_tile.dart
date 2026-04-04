import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/presentation/presentation.dart';

class GoalTile extends StatelessWidget {
  const GoalTile({required this.currentGoal, super.key});

  final int currentGoal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingXXL,
        vertical: AppConstants.paddingXS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.settingsDailyGoal.tr(context: context),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppConstants.paddingS),
          Wrap(
            spacing: AppConstants.paddingS,
            children: AppConstants.dailyGoalOptions.map((goal) {
              final isSelected = goal == currentGoal;
              return ChoiceChip(
                label: Text(
                  '$goal',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                selected: isSelected,
                onSelected: (_) =>
                    context.read<SettingsCubit>().updateDailyGoal(goal),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
