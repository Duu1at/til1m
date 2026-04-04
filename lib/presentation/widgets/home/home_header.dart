import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/theme/app_colors.dart';
import 'package:til1m/presentation/blocs/home/home_cubit.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.data,
    super.key,
    this.userName,
  });

  final HomeData data;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final levelText = data.userLevel.toUpperCase();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(context),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (userName != null && userName!.isNotEmpty)
                Text(
                  userName!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppConstants.paddingL),
        _LevelBadge(levelText: levelText),
      ],
    );
  }

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    return switch (hour) {
      < 12 => LocaleKeys.homeGreetingMorning.tr(context: context),
      < 17 => LocaleKeys.homeGreetingAfternoon.tr(context: context),
      _ => LocaleKeys.homeGreetingEvening.tr(context: context),
    };
  }
}

final class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.levelText});

  final String levelText;

  @override
  Widget build(BuildContext context) {
    final levelColor = AppColors.level[levelText] ?? AppColors.indigo500;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(
          color: levelColor.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingXS,
        ),
        child: Text(
          levelText,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: levelColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
