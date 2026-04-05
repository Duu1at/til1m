import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/presentation/blocs/blocs.dart';

final class StatusRow extends StatelessWidget {
  const StatusRow({required this.statusFilter, super.key});

  final WordStatusFilter statusFilter;

  static const List<(WordStatusFilter, String)> _items = [
    (WordStatusFilter.all, LocaleKeys.dictionaryFilterAll),
    (WordStatusFilter.newWord, LocaleKeys.dictionaryFilterNew),
    (WordStatusFilter.learning, LocaleKeys.dictionaryFilterLearning),
    (WordStatusFilter.known, LocaleKeys.dictionaryFilterKnown),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingL,
          AppConstants.paddingXS,
          AppConstants.paddingL,
          AppConstants.paddingXS,
        ),
        itemCount: _items.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppConstants.paddingXS),
        itemBuilder: (context, i) {
          final (filter, key) = _items[i];
          final selected = statusFilter == filter;
          return FilterChip(
            label: Text(
              key.tr(context: context),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            selected: selected,
            onSelected: (_) =>
                context.read<DictionaryCubit>().onStatusFilterChanged(filter),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingXS,
            ),
            labelStyle: const TextStyle(fontSize: 13),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}
