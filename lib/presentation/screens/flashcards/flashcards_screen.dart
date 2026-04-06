import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/di/service_locator.dart';
import 'package:til1m/data/datasources/local/progress_local_datasource.dart';
import 'package:til1m/data/datasources/local/word_local_datasource.dart';
import 'package:til1m/data/datasources/remote/progress_remote_datasource.dart';
import 'package:til1m/data/datasources/remote/word_remote_datasource.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/presentation/blocs/flashcards/flashcards_bloc.dart';
import 'package:til1m/presentation/blocs/flashcards/flashcards_event.dart';
import 'package:til1m/presentation/widgets/flashcards/flashcards.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FlashcardsBloc(
        authRepo: sl<AuthRepository>(),
        progressLocal: sl<ProgressLocalDataSource>(),
        progressRemote: sl<ProgressRemoteDataSource>(),
        wordRemote: sl<WordRemoteDataSource>(),
        wordLocal: sl<WordLocalDataSource>(),
      )..add(const FlashcardsStartRequested()),
      child: const _FlashcardsView(),
    );
  }
}

final class _FlashcardsView extends StatelessWidget {
  const _FlashcardsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.flashcardsTitle.tr(context: context)),
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<FlashcardsBloc, FlashcardsState>(
        builder: (context, state) => switch (state) {
          FlashcardsInitial() ||
          FlashcardsLoading() =>
            const Center(child: CircularProgressIndicator()),
          FlashcardsEmpty() => const FlashcardEmpty(),
          FlashcardsActive(:final queue, :final currentIndex, :final isFlipped, :final stats, :final uiLanguage) =>
            _ActiveSessionView(
              queue: queue,
              currentIndex: currentIndex,
              isFlipped: isFlipped,
              stats: stats,
              uiLanguage: uiLanguage,
            ),
          FlashcardsSessionComplete(:final stats) => FlashcardSessionComplete(
            stats: stats,
            onRestart: () => context
                .read<FlashcardsBloc>()
                .add(const FlashcardsSessionRestarted()),
            onFinish: () => context.pop(),
          ),
          FlashcardsError(:final message) => _ErrorView(message: message),
        },
      ),
    );
  }
}

// ─── Active session ───────────────────────────────────────────────────────────

final class _ActiveSessionView extends StatelessWidget {
  const _ActiveSessionView({
    required this.queue,
    required this.currentIndex,
    required this.isFlipped,
    required this.stats,
    required this.uiLanguage,
  });

  final List<FlashcardItem> queue;
  final int currentIndex;
  final bool isFlipped;
  final FlashcardsSessionStats stats;
  final String uiLanguage;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FlashcardsBloc>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingL,
        ),
        child: Column(
          children: [
            // Progress bar
            FlashcardProgressBar(
              current: currentIndex + 1,
              total: queue.length,
            ),
            const SizedBox(height: AppConstants.paddingXXL),

            // Card (takes remaining space)
            Expanded(
              child: FlashcardContainer(
                item: queue[currentIndex],
                isFlipped: isFlipped,
                currentIndex: currentIndex,
                uiLanguage: uiLanguage,
                onTap: () =>
                    bloc.add(const FlashcardsCardFlipRequested()),
              ),
            ),
            const SizedBox(height: AppConstants.paddingXXL),

            // Answer buttons — visible only after flip
            AnimatedSwitcher(
              duration: AppConstants.durationNormal,
              child: isFlipped
                  ? FlashcardAnswerButtons(
                      key: const ValueKey('buttons'),
                      onKnew: () => bloc.add(
                        const FlashcardsAnswerSubmitted(knew: true),
                      ),
                      onDidntKnow: () => bloc.add(
                        const FlashcardsAnswerSubmitted(knew: false),
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('placeholder'),
                      height: AppConstants.buttonHeight,
                    ),
            ),
            const SizedBox(height: AppConstants.paddingL),
          ],
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

final class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSection),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              LocaleKeys.errorsGeneric.tr(context: context),
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingXXL),
            FilledButton(
              onPressed: () => context
                  .read<FlashcardsBloc>()
                  .add(const FlashcardsStartRequested()),
              child: Text(LocaleKeys.errorsTryAgain.tr(context: context)),
            ),
          ],
        ),
      ),
    );
  }
}
