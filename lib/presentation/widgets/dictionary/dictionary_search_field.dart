import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/presentation/blocs/blocs.dart';

class DictionarySearchField extends StatefulWidget {
  const DictionarySearchField({super.key});

  @override
  State<DictionarySearchField> createState() => _DictionarySearchFieldState();
}

final class _DictionarySearchFieldState extends State<DictionarySearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      onChanged: context.read<DictionaryCubit>().onQueryChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: LocaleKeys.dictionarySearchHint.tr(context: context),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (_, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _controller.clear();
                    context.read<DictionaryCubit>().onQueryChanged('');
                  },
                ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingS,
        ),
        isDense: true,
      ),
    );
  }
}
