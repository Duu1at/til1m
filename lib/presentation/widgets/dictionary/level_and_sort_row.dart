import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/theme/app_colors.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/presentation/blocs/blocs.dart';

final class LevelAndSortRow extends StatelessWidget {
  const LevelAndSortRow({
    required this.levelFilter,
    required this.sort,
    super.key,
  });

  final WordLevel? levelFilter;
  final DictionarySort sort;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingL,
          AppConstants.paddingXS,
          AppConstants.paddingS,
          AppConstants.paddingXS,
        ),
        itemCount: WordLevel.values.length + 1,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppConstants.paddingXS),
        itemBuilder: (context, i) {
          if (i == 0) {
            return FilterChip(
              label: Text(
                LocaleKeys.dictionaryFilterAll.tr(context: context),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              selected: levelFilter == null,
              onSelected: (_) =>
                  context.read<DictionaryCubit>().onLevelFilterChanged(null),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingXS,
              ),
              labelStyle: const TextStyle(fontSize: 13),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }
          final level = WordLevel.values[i - 1];
          final text = level.label;
          final color = AppColors.level[text] ?? AppColors.indigo500;
          final selected = levelFilter == level;
          return FilterChip(
            label: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            selected: selected,
            onSelected: (_) =>
                context.read<DictionaryCubit>().onLevelFilterChanged(level),
            showCheckmark: false,
            selectedColor: color.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              fontSize: 13,
              color: selected ? color : null,
              fontWeight: selected ? FontWeight.w600 : null,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingXS,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}
