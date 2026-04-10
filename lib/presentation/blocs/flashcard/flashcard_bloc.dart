import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/network/connectivity_service.dart';
import 'package:til1m/data/datasources/sync/progress_sync_service.dart';
import 'package:til1m/data/repositories/flashcard_repository_impl.dart';
import 'package:til1m/data/services/update_home_widget.dart';
import 'package:til1m/domain/entities/flashcard_session.dart';
import 'package:til1m/domain/entities/user_progress.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/entities/word_progress.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/domain/usecases/calculate_sm2.dart';

part 'flashcard_event.dart';
part 'flashcard_state.dart';

/// Maximum times a wrong-answered word is re-added to the queue per session.
const _maxRetries = 3;

/// Maximum depth of the undo stack.
const _maxUndoDepth = 5;

/// Number of new words appended per [FlashcardLoadMore] request.
const _loadMoreLimit = 10;

// Private record type used on the undo stack.
typedef _UndoEntry = ({
  FlashcardSession session,
  Map<String, int> retryCounts,
  UndoAction action,
});

final class FlashcardBloc extends Bloc<FlashcardEvent, FlashcardState> {
  FlashcardBloc({
    required FlashcardRepositoryImpl flashcardRepo,
    required AuthRepository authRepo,
    required ConnectivityService connectivity,
    required ProgressSyncService syncService,
    required UpdateHomeWidget updateHomeWidget,
  }) : _repo = flashcardRepo,
       _authRepo = authRepo,
       _connectivity = connectivity,
       _syncService = syncService,
       _updateHomeWidget = updateHomeWidget,
       super(const FlashcardInitial()) {
    on<FlashcardStartSession>(_onStartSession);
    on<FlashcardResumeSession>(_onResumeSession);
    on<FlashcardFlipCard>(_onFlipCard);
    on<FlashcardAnswer>(_onAnswer);
    on<FlashcardUndo>(_onUndo);
    on<FlashcardSkip>(_onSkip);
    on<FlashcardPlayAudio>(_onPlayAudio);
    on<FlashcardEndSession>(_onEndSession);
    on<FlashcardLoadMore>(_onLoadMore);
    on<_ConnectivityChanged>(_onConnectivityChanged);
    unawaited(_initTts());
    _subscribeConnectivity();
  }

  final FlashcardRepositoryImpl _repo;
  final AuthRepository _authRepo;
  final ConnectivityService _connectivity;
  final ProgressSyncService _syncService;
  final UpdateHomeWidget _updateHomeWidget;

  static const _sm2 = CalculateSm2();

  FlashcardSession _session = FlashcardSession(
    items: const [],
    sessionStartedAt: DateTime(2000),
  );

  Map<String, int> _retryCounts = {};

  final Set<String> _loadedNewWordIds = {};

  final List<_UndoEntry> _undoStack = [];

  bool _isAudioPlaying = false;
  bool _isOffline = false;
  StreamSubscription<bool>? _connectivitySub;

  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(AppConstants.ttsDefaultRate);
      await _tts.setVolume(1);
      await _tts.setPitch(1);
      _ttsReady = true;
    } on Object catch (e, st) {
      debugPrint('[FlashcardBloc] TTS init: $e\n$st');
    }
  }

  void _subscribeConnectivity() {
    _isOffline = !_connectivity.isOnline;
    _connectivitySub = _connectivity.onlineStream.listen(
      (online) => add(_ConnectivityChanged(isOnline: online)),
    );
  }

  Future<void> _onConnectivityChanged(
    _ConnectivityChanged event,
    Emitter<FlashcardState> emit,
  ) async {
    _isOffline = !event.isOnline;

    if (state is! FlashcardActive) return;
    final s = state as FlashcardActive;

    if (!event.isOnline) {
      emit(s.copyWith(isOffline: true));
      return;
    }

    emit(s.copyWith(isOffline: false));
    final userId = _authRepo.currentUserId;
    if (userId == null || _authRepo.isGuest) return;

    final result = await _syncService.flush(userId);
    if (result.outcome == SyncOutcome.noData) return;

    final message = switch (result.outcome) {
      SyncOutcome.success || SyncOutcome.partialSuccess =>
        'Прогресс синхронизирован (${result.syncedCount} слов)',
      SyncOutcome.error => 'Ошибка синхронизации: ${result.errorMessage ?? ""}',
      SyncOutcome.noData => null,
    };

    if (message != null && state is FlashcardActive) {
      emit((state as FlashcardActive).copyWith(syncMessage: message));
    }
  }

  @override
  Future<void> close() async {
    await _connectivitySub?.cancel();
    await _tts.stop();
    if (_session.items.isNotEmpty && !_session.isComplete) {
      unawaited(_repo.saveSession(_session));
    }
    return super.close();
  }

  String get _userId => _authRepo.currentUserId ?? 'guest';

  Future<WordLevel> _userLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyUserLevel) ?? '';
    return WordLevel.values.firstWhere(
      (l) => l.name.toLowerCase() == raw.toLowerCase(),
      orElse: () => WordLevel.a1,
    );
  }

  FlashcardActive _buildActive({bool isFlipped = false}) {
    final item = _session.current!;
    return FlashcardActive(
      currentWord: item.word,
      currentProgress: item.progress,
      isCurrentReview: item.isReview,
      isFlipped: isFlipped,
      currentIndex: _session.currentIndex,
      totalWords: _session.total,
      answeredCount: _session.answeredCount,
      correctCount: _session.correctCount,
      reviewCount: _session.reviewItems.length,
      newCount: _session.newItems.length,
      canUndo: _undoStack.isNotEmpty,
      isAudioPlaying: _isAudioPlaying,
      isOffline: _isOffline,
    );
  }

  UserWordProgress _toUserProgress(WordProgress p) => UserWordProgress(
    id: '${_userId}_${p.wordId}',
    userId: _userId,
    wordId: p.wordId,
    status: p.status,
    easeFactor: p.easeFactor,
    repetitions: p.repetitions,
    nextReviewAt: p.nextReviewAt,
    lastReviewedAt: p.lastReviewedAt,
  );

  Future<void> _onStartSession(
    FlashcardStartSession event,
    Emitter<FlashcardState> emit,
  ) async {
    emit(const FlashcardLoading());
    _retryCounts = {};
    _loadedNewWordIds.clear();
    _undoStack.clear();

    try {
      final reviewItems = <FlashcardSessionItem>[];
      final newItems = <FlashcardSessionItem>[];

      if (event.source != FlashcardSource.newWords) {
        final items = await _repo.getReviewSessionItems(_userId);
        reviewItems.addAll(items);
      }

      if (event.source != FlashcardSource.review) {
        final level = await _userLevel();
        final excludedIds = await _repo.getProgressWordIds(_userId);
        _loadedNewWordIds.addAll(excludedIds);

        final words = await _repo.getNewWords(
          level: level,
          excludeIds: excludedIds,
          limit: _loadMoreLimit,
        );
        for (final w in words) {
          _loadedNewWordIds.add(w.id);
          newItems.add(
            FlashcardSessionItem(
              word: w,
              progress: WordProgress(wordId: w.id),
            ),
          );
        }
      }

      final allItems = [...reviewItems, ...newItems];
      if (allItems.isEmpty) {
        emit(FlashcardEmpty(source: event.source));
        return;
      }

      _session = FlashcardSession(
        items: allItems,
        sessionStartedAt: DateTime.now(),
      );

      emit(_buildActive());
    } on Object catch (e, st) {
      debugPrint('[FlashcardBloc] _onStartSession: $e\n$st');
      emit(FlashcardError(message: e.toString()));
    }
  }

  Future<void> _onResumeSession(
    FlashcardResumeSession event,
    Emitter<FlashcardState> emit,
  ) async {
    emit(const FlashcardLoading());
    _undoStack.clear();

    try {
      final restored = await _repo.restoreSession();
      if (restored == null || restored.isComplete) {
        add(const FlashcardStartSession(source: FlashcardSource.mixed));
        return;
      }

      _session = restored;

      for (final item in restored.items) {
        _loadedNewWordIds.add(item.word.id);
      }

      if (!isClosed) emit(_buildActive());
    } on Object catch (e, st) {
      debugPrint('[FlashcardBloc] _onResumeSession: $e\n$st');
      emit(FlashcardError(message: e.toString()));
    }
  }

  void _onFlipCard(FlashcardFlipCard event, Emitter<FlashcardState> emit) {
    final s = state;
    if (s is! FlashcardActive) return;
    emit(s.copyWith(isFlipped: !s.isFlipped));
  }

  Future<void> _onAnswer(
    FlashcardAnswer event,
    Emitter<FlashcardState> emit,
  ) async {
    if (state is! FlashcardActive || _session.current == null) return;

    final currentItem = _session.current!;
    final previousProgress = currentItem.progress;

    final undoAction = UndoAction(
      item: currentItem,
      wasCorrect: event.isCorrect,
      previousProgress: previousProgress,
    );
    final undoEntry = (
      session: _session,
      retryCounts: Map<String, int>.of(_retryCounts),
      action: undoAction,
    );
    _undoStack.add(undoEntry);
    if (_undoStack.length > _maxUndoDepth) _undoStack.removeAt(0);

    final sm2Result = _sm2.calculate(
      current: previousProgress,
      isCorrect: event.isCorrect,
    );
    final updatedProgress = sm2Result.updatedProgress;

    unawaited(_repo.saveProgress(_toUserProgress(updatedProgress)));

    // Update home widget when user learns a new (non-review) word.
    if (event.isCorrect && !currentItem.isReview) {
      unawaited(_updateHomeWidget.call());
    }

    final wordId = currentItem.word.id;
    final nextItems = List<FlashcardSessionItem>.of(_session.items);

    if (!event.isCorrect) {
      final retries = _retryCounts[wordId] ?? 0;
      if (retries < _maxRetries) {
        _retryCounts[wordId] = retries + 1;
        nextItems.add(
          FlashcardSessionItem(
            word: currentItem.word,
            progress: updatedProgress,
            isReview: currentItem.isReview,
          ),
        );
      }
    }

    _session = _session.copyWith(
      items: nextItems,
      currentIndex: _session.currentIndex + 1,
      answeredCount: _session.answeredCount + 1,
      correctCount: event.isCorrect
          ? _session.correctCount + 1
          : _session.correctCount,
    );

    if (_session.isComplete) {
      add(const FlashcardEndSession());
      return;
    }

    if (!isClosed) emit(_buildActive());
  }

  Future<void> _onUndo(
    FlashcardUndo event,
    Emitter<FlashcardState> emit,
  ) async {
    if (_undoStack.isEmpty) return;

    final entry = _undoStack.removeLast();

    unawaited(
      _repo.saveProgress(_toUserProgress(entry.action.previousProgress)),
    );

    _session = entry.session;
    _retryCounts = entry.retryCounts;

    if (!isClosed) emit(_buildActive());
  }

  void _onSkip(FlashcardSkip event, Emitter<FlashcardState> emit) {
    if (state is! FlashcardActive || _session.current == null) return;

    _session = _session.copyWith(
      currentIndex: _session.currentIndex + 1,
    );

    if (_session.isComplete) {
      add(const FlashcardEndSession());
      return;
    }

    emit(_buildActive());
  }

  Future<void> _onPlayAudio(
    FlashcardPlayAudio event,
    Emitter<FlashcardState> emit,
  ) async {
    final s = state;
    if (s is! FlashcardActive || _isAudioPlaying) return;

    _isAudioPlaying = true;
    emit(s.copyWith(isAudioPlaying: true));

    final completer = Completer<void>();
    _tts
      ..setCompletionHandler(() {
        if (!completer.isCompleted) completer.complete();
      })
      ..setErrorHandler((msg) {
        debugPrint('[FlashcardBloc] TTS error: $msg');
        if (!completer.isCompleted) completer.complete();
      });

    try {
      if (!_ttsReady) await _initTts();
      await _tts.speak(s.currentWord.word);
      await completer.future;
    } on Object catch (e, st) {
      debugPrint('[FlashcardBloc] playAudio: $e\n$st');
    } finally {
      _isAudioPlaying = false;
      if (!isClosed) {
        final curr = state;
        if (curr is FlashcardActive) emit(curr.copyWith(isAudioPlaying: false));
      }
    }
  }

  Future<void> _onEndSession(
    FlashcardEndSession event,
    Emitter<FlashcardState> emit,
  ) async {
    await _repo.clearSession();
    _undoStack.clear();

    final sessionDuration = DateTime.now().difference(
      _session.sessionStartedAt,
    );
    final prefs = await SharedPreferences.getInstance();
    final dailyGoal = prefs.getInt(AppConstants.keyDailyGoal) ?? 5;

    var todayReviewed = 0;
    try {
      todayReviewed = await _repo.getTodayLearnedCount(_userId);
    } on Object catch (e, st) {
      debugPrint('[FlashcardBloc] getTodayLearnedCount: $e\n$st');
    }

    if (!isClosed) {
      emit(
        FlashcardSessionComplete(
          totalAnswered: _session.answeredCount,
          correctCount: _session.correctCount,
          incorrectCount: _session.incorrectCount,
          newWordsLearned: _session.newItems.length,
          wordsReviewed: _session.reviewItems.length,
          sessionDuration: sessionDuration,
          dailyGoalReached: todayReviewed >= dailyGoal,
        ),
      );
      // Refresh the home-screen widget with the latest progress.
      unawaited(_updateHomeWidget.call());
    }
  }

  Future<void> _onLoadMore(
    FlashcardLoadMore event,
    Emitter<FlashcardState> emit,
  ) async {
    if (state is! FlashcardActive) return;

    try {
      final level = await _userLevel();
      final excludeIds = List<String>.of(_loadedNewWordIds);

      final words = await _repo.getNewWords(
        level: level,
        excludeIds: excludeIds,
        limit: _loadMoreLimit,
      );

      if (words.isEmpty) return;

      final newItems = <FlashcardSessionItem>[];
      for (final w in words) {
        _loadedNewWordIds.add(w.id);
        newItems.add(
          FlashcardSessionItem(
            word: w,
            progress: WordProgress(wordId: w.id),
          ),
        );
      }

      _session = _session.copyWith(
        items: [..._session.items, ...newItems],
      );

      if (!isClosed) emit(_buildActive());
    } on Object catch (e, st) {
      debugPrint('[FlashcardBloc] _onLoadMore: $e\n$st');
    }
  }
}
