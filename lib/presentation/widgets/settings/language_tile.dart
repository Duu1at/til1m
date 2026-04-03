import 'dart:async' show unawaited;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/presentation/presentation.dart';

class LanguageTile extends StatelessWidget {
  const LanguageTile({required this.currentLanguage, super.key});

  final UiLanguage currentLanguage;

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
          SegmentedButton<UiLanguage>(
            segments: [
              ButtonSegment(
                value: UiLanguage.ru,
                label: Text(LocaleKeys.langSelectRu.tr()),
              ),
              ButtonSegment(
                value: UiLanguage.ky,
                label: Text(LocaleKeys.langSelectKy.tr()),
              ),
            ],
            selected: {currentLanguage},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) {
                unawaited(
                  context.read<SettingsCubit>().updateLanguage(selection.first),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
