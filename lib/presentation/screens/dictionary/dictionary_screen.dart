import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/di/service_locator.dart';
import 'package:til1m/data/datasources/local/word_local_datasource.dart';
import 'package:til1m/data/datasources/remote/word_remote_datasource.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/presentation/presentation.dart';

class DictionaryScreen extends StatelessWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DictionaryCubit(
        authRepo: sl<AuthRepository>(),
        wordRemote: sl<WordRemoteDataSource>(),
        wordLocal: sl<WordLocalDataSource>(),
      ),
      child: const _DictionaryView(),
    );
  }
}

final class _DictionaryView extends StatelessWidget {
  const _DictionaryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DictionaryCubit, DictionaryState>(
        builder: (context, state) {
          if (state is DictionaryInitial || state is DictionaryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final loaded = state as DictionaryLoaded;
          return _DictionaryBody(state: loaded);
        },
      ),
    );
  }
}

final class _DictionaryBody extends StatefulWidget {
  const _DictionaryBody({required this.state});

  final DictionaryLoaded state;

  @override
  State<_DictionaryBody> createState() => _DictionaryBodyState();
}

final class _DictionaryBodyState extends State<_DictionaryBody> {
  final _scrollController = ScrollController();

  static const double _searchHeight = 44;
  static const double _sliverBottomHeight =
      AppConstants.paddingM +
      _searchHeight +
      AppConstants.paddingS +
      DictionaryFilterBar.height +
      AppConstants.paddingXS +
      1.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(context.read<DictionaryCubit>().loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final words = widget.state.words;
    final hasMore = widget.state.hasMore;
    final isLoadingMore = widget.state.isLoadingMore;
    final isFiltering = widget.state.isFiltering;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          title: Text(LocaleKeys.dictionaryTitle.tr(context: context)),
          actions: [
            _SortButton(sort: widget.state.sort),
            const SizedBox(width: AppConstants.paddingS),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(_sliverBottomHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppConstants.paddingL,
                    AppConstants.paddingM,
                    AppConstants.paddingL,
                    AppConstants.paddingS,
                  ),
                  child: DictionarySearchField(),
                ),
                DictionaryFilterBar(state: widget.state),
                const SizedBox(height: AppConstants.paddingXS),
                const Divider(height: 1),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: isFiltering
              ? LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                )
              : const SizedBox.shrink(),
        ),
        if (words.isEmpty && !isFiltering)
          const SliverFillRemaining(child: _EmptyState())
        else
          SliverList.separated(
            itemCount: words.length + (hasMore || isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              indent: AppConstants.paddingL,
              endIndent: AppConstants.paddingL,
            ),
            itemBuilder: (context, index) {
              if (index >= words.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppConstants.paddingL),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return WordListTile(item: words[index], lang: lang);
            },
          ),
      ],
    );
  }
}

final class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort});

  final DictionarySort sort;

  @override
  Widget build(BuildContext context) {
    final isAlpha = sort == DictionarySort.alphabetical;
    return Tooltip(
      message: isAlpha
          ? LocaleKeys.dictionarySortLevel.tr(context: context)
          : LocaleKeys.dictionarySortAlpha.tr(context: context),
      child: IconButton(
        icon: Icon(
          isAlpha ? Icons.sort_by_alpha_rounded : Icons.layers_rounded,
          size: 22,
        ),
        onPressed: () => context.read<DictionaryCubit>().onSortChanged(
          isAlpha ? DictionarySort.byLevel : DictionarySort.alphabetical,
        ),
      ),
    );
  }
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: colorScheme.outline),
          const SizedBox(height: AppConstants.paddingL),
          Text(
            LocaleKeys.dictionaryEmpty.tr(context: context),
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
