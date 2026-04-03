import 'dart:async' show unawaited;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/presentation/presentation.dart';

class LevelTile extends StatelessWidget {
  const LevelTile({required this.currentLevel, super.key});

  final WordLevel currentLevel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingXXL,
        vertical: AppConstants.paddingXS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            LocaleKeys.settingsLevel.tr(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          DropdownButton<WordLevel>(
            value: currentLevel,
            underline: const SizedBox.shrink(),
            items: WordLevel.values.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text(level.name.toUpperCase()),
              );
            }).toList(),
            onChanged: (level) {
              if (level != null) {
                unawaited(context.read<SettingsCubit>().updateLevel(level));
              }
            },
          ),
        ],
      ),
    );
  }
}
