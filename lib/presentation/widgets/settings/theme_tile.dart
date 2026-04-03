import 'dart:async' show unawaited;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/domain/entities/user_settings.dart';
import 'package:til1m/presentation/presentation.dart';

class ThemeTile extends StatelessWidget {
  const ThemeTile({required this.currentTheme, super.key});

  final AppTheme currentTheme;

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
          SegmentedButton<AppTheme>(
            segments: [
              ButtonSegment(
                value: AppTheme.light,
                label: Text(LocaleKeys.settingsThemeLight.tr()),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: AppTheme.system,
                label: Text(LocaleKeys.settingsThemeSystem.tr()),
                icon: const Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: AppTheme.dark,
                label: Text(LocaleKeys.settingsThemeDark.tr()),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {currentTheme},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) {
                unawaited(
                  context.read<SettingsCubit>().updateTheme(selection.first),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
