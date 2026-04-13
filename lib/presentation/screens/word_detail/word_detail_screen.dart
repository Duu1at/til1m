import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/di/service_locator.dart';
import 'package:til1m/data/datasources/local/progress_local_datasource.dart';
import 'package:til1m/data/datasources/remote/progress_remote_datasource.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/domain/repositories/word_repository.dart';
import 'package:til1m/presentation/blocs/word_detail/word_detail_cubit.dart';
import 'package:til1m/presentation/widgets/word_detail/word_detail.dart';
import 'package:til1m/presentation/widgets/word_detail/word_detail_shimmer.dart';

class WordDetailScreen extends StatelessWidget {
  const WordDetailScreen({required this.wordId, super.key});

  final String wordId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = WordDetailCubit(
          wordRepository: sl<WordRepository>(),
          progressLocal: sl<ProgressLocalDataSource>(),
          progressRemote: sl<ProgressRemoteDataSource>(),
          authRepository: sl<AuthRepository>(),
        );
        unawaited(cubit.load(wordId));
        return cubit;
      },
      child: const _WordDetailView(),
    );
  }
}

final class _WordDetailView extends StatelessWidget {
  const _WordDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WordDetailCubit, WordDetailState>(
      listenWhen: (prev, curr) =>
          prev is WordDetailLoaded &&
          curr is WordDetailLoaded &&
          prev.isProcessingProgress &&
          !curr.isProcessingProgress,
      listener: (context, state) {
        if (state is! WordDetailLoaded) return;
        final knew = state.lastAnswerKnew;
        if (knew == null) return;
        final msg = knew
            ? LocaleKeys.wordBtnKnow.tr(context: context)
            : LocaleKeys.wordBtnDontKnow.tr(context: context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      builder: (context, state) => switch (state) {
        WordDetailInitial() || WordDetailLoading() => const WordDetailShimmer(),
        WordDetailError(:final message) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(message)),
          ),
        WordDetailLoaded() => _LoadedScaffold(state: state),
      },
    );
  }
}

final class _LoadedScaffold extends StatelessWidget {
  const _LoadedScaffold({required this.state});

  final WordDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              state.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: state.isFavorite ? colorScheme.error : null,
            ),
            tooltip: state.isFavorite
                ? LocaleKeys.wordRemoveFavorite.tr(context: context)
                : LocaleKeys.wordAddFavorite.tr(context: context),
            onPressed: () => context.read<WordDetailCubit>().toggleFavorite(),
          ),
        ],
      ),
      body: WordDetailBody(state: state),
      bottomNavigationBar: WordKnowButtons(state: state),
    );
  }
}
