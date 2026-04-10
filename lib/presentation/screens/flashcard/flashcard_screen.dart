import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/di/service_locator.dart';
import 'package:til1m/core/network/connectivity_service.dart';
import 'package:til1m/data/datasources/sync/progress_sync_service.dart';
import 'package:til1m/data/repositories/flashcard_repository_impl.dart';
import 'package:til1m/data/services/update_home_widget.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/domain/usecases/prefetch_flashcard_data.dart';
import 'package:til1m/presentation/blocs/flashcard/flashcard_bloc.dart';
import 'package:til1m/presentation/widgets/auth/soft_auth_prompt.dart';
import 'package:til1m/presentation/widgets/flashcard/flashcard_card.dart';
import 'package:til1m/presentation/widgets/flashcard/flashcard_empty_screen.dart';
import 'package:til1m/presentation/widgets/flashcard/flashcard_progress_bar.dart';
import 'package:til1m/presentation/widgets/flashcard/flashcard_result_screen.dart';

class FlashcardScreen extends StatelessWidget {
  const FlashcardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        // Kick off background prefetch so next offline session has fresh data.
        unawaited(sl<PrefetchFlashcardData>().call());
        return FlashcardBloc(
          flashcardRepo: sl<FlashcardRepositoryImpl>(),
          authRepo: sl<AuthRepository>(),
          connectivity: sl<ConnectivityService>(),
          syncService: sl<ProgressSyncService>(),
          updateHomeWidget: sl<UpdateHomeWidget>(),
        )..add(const FlashcardStartSession(source: FlashcardSource.mixed));
      },
      child: const _FlashcardView(),
    );
  }
}

// ─── Root view ────────────────────────────────────────────────────────────────

class _FlashcardView extends StatelessWidget {
  const _FlashcardView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlashcardBloc, FlashcardState>(
      listenWhen: (prev, curr) {
        // Sync message changed while active.
        if (curr is FlashcardActive) {
          final prevMsg = prev is FlashcardActive ? prev.syncMessage : null;
          if (curr.syncMessage != null && curr.syncMessage != prevMsg) return true;
        }
        // Session just completed.
        if (curr is FlashcardSessionComplete && prev is! FlashcardSessionComplete) {
          return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state is FlashcardActive && state.syncMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.syncMessage!),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        if (state is FlashcardSessionComplete) {
          unawaited(
            SoftAuthPrompt.showIfNeeded(
              context,
              authRepo: sl<AuthRepository>(),
              trigger: SoftAuthTrigger.sessionComplete,
            ),
          );
        }
      },
      builder: (context, state) {
        return switch (state) {
          FlashcardInitial() || FlashcardLoading() => const _LoadingScaffold(),
          FlashcardActive() => _ActiveScaffold(state: state),
          FlashcardSessionComplete() => _ResultScaffold(state: state),
          FlashcardEmpty(:final source) => _EmptyScaffold(source: source),
          FlashcardError(:final message) => _ErrorScaffold(message: message),
        };
      },
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context, showActions: false),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

// ─── Active session ───────────────────────────────────────────────────────────

class _ActiveScaffold extends StatelessWidget {
  const _ActiveScaffold({required this.state});

  final FlashcardActive state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FlashcardBloc>();
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      appBar: _buildAppBar(
        context,
        showActions: true,
        canUndo: state.canUndo,
        onUndo: () => bloc.add(const FlashcardUndo()),
        onSkip: () => bloc.add(const FlashcardSkip()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
          ),
          child: Column(
            children: [
              if (state.isOffline) const _OfflineBanner(),

              const SizedBox(height: AppConstants.paddingM),

              FlashcardProgressBar(
                current: state.currentIndex + 1,
                total: state.totalWords,
                reviewCount: state.reviewCount,
                newCount: state.newCount,
              ),
              SizedBox(height: screenHeight * 0.025),

              Expanded(
                child: AnimatedSwitcher(
                  duration: AppConstants.durationNormal,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: FlashcardCard(
                    key: ValueKey(state.currentWord.id),
                    word: state.currentWord,
                    progress: state.currentProgress,
                    isCurrentReview: state.isCurrentReview,
                    isFlipped: state.isFlipped,
                    isAudioPlaying: state.isAudioPlaying,
                    onFlip: () => bloc.add(const FlashcardFlipCard()),
                    onKnow: () =>
                        bloc.add(const FlashcardAnswer(isCorrect: true)),
                    onDontKnow: () =>
                        bloc.add(const FlashcardAnswer(isCorrect: false)),
                    onAudio: () => bloc.add(const FlashcardPlayAudio()),
                  ),
                ),
              ),

              AnimatedCrossFade(
                duration: AppConstants.durationNormal,
                crossFadeState: state.canUndo
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: TextButton.icon(
                  onPressed: () => bloc.add(const FlashcardUndo()),
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Отменить'),
                ),
                secondChild: const SizedBox(height: AppConstants.buttonHeightS),
              ),
              const SizedBox(height: AppConstants.paddingM),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultScaffold extends StatelessWidget {
  const _ResultScaffold({required this.state});

  final FlashcardSessionComplete state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FlashcardBloc>();
    return Scaffold(
      appBar: _buildAppBar(context, showActions: false),
      body: FlashcardResultScreen(
        state: state,
        onStudyMore: () => bloc.add(
          const FlashcardStartSession(source: FlashcardSource.mixed),
        ),
        onGoHome: () => context.go('/home'),
      ),
    );
  }
}

class _EmptyScaffold extends StatelessWidget {
  const _EmptyScaffold({required this.source});

  final FlashcardSource source;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FlashcardBloc>();
    return Scaffold(
      appBar: _buildAppBar(context, showActions: false),
      body: FlashcardEmptyScreen(
        source: source,
        onLoadMore: () => bloc.add(const FlashcardLoadMore()),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bloc = context.read<FlashcardBloc>();

    return Scaffold(
      appBar: _buildAppBar(context, showActions: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSection),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: colorScheme.error,
              ),
              const SizedBox(height: AppConstants.paddingL),
              Text(
                LocaleKeys.errorsGeneric.tr(context: context),
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingSection),
              FilledButton(
                onPressed: () => bloc.add(
                  const FlashcardStartSession(source: FlashcardSource.mixed),
                ),
                child: Text(LocaleKeys.errorsTryAgain.tr(context: context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingXS,
        ),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 16,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: AppConstants.paddingS),
            Text(
              'Офлайн-режим · прогресс сохраняется локально',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

AppBar _buildAppBar(
  BuildContext context, {
  required bool showActions,
  bool canUndo = false,
  VoidCallback? onUndo,
  VoidCallback? onSkip,
}) {
  final bloc = context.read<FlashcardBloc>();

  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      tooltip: 'Закрыть',
      onPressed: () {
        unawaited(bloc.close());
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
    ),
    title: Text(LocaleKeys.flashcardsTitle.tr(context: context)),
    centerTitle: false,
    surfaceTintColor: Colors.transparent,
    actions: showActions
        ? [
            if (onSkip != null)
              TextButton(
                onPressed: onSkip,
                child: const Text('Пропустить'),
              ),
            const SizedBox(width: AppConstants.paddingS),
          ]
        : null,
  );
}
