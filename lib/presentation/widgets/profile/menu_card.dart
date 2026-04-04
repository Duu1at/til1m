import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/router/app_router.dart';
import 'package:til1m/presentation/presentation.dart';

class MenuCard extends StatelessWidget {
  const MenuCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            theme.cardTheme.color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      ),
      child: Column(
        children: [
          MenuItem(
            icon: Icons.bar_chart_rounded,
            label: LocaleKeys.statisticsTitle.tr(context: context),
            onTap: () => context.go(AppRoutes.statistics),
            isFirst: true,
          ),
          Divider(
            height: AppConstants.dividerThickness,
            thickness: AppConstants.dividerThickness,
            indent: AppConstants.paddingXXL + 22 + AppConstants.paddingM,
            color: theme.dividerColor,
          ),
          MenuItem(
            icon: Icons.settings_outlined,
            label: LocaleKeys.settingsTitle.tr(context: context),
            onTap: () => context.go(AppRoutes.settings),
            isLast: true,
          ),
        ],
      ),
    );
  }
}
