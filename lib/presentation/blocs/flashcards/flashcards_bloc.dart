import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/data/datasources/local/progress_local_datasource.dart';
import 'package:til1m/data/datasources/local/word_local_datasource.dart';
import 'package:til1m/data/datasources/remote/progress_remote_datasource.dart';
import 'package:til1m/data/datasources/remote/word_remote_datasource.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/presentation/blocs/flashcards/flashcards_event.dart';

part 'flashcards_state.dart';

class FlashcardsBloc extends Bloc<FlashcardsEvent, FlashcardsState> {
  FlashcardsBloc({
    required AuthRepository authRepo,
    required ProgressLocalDataSource progressLocal,
    required ProgressRemoteDataSource progressRemote,
    required WordRemoteDataSource wordRemote,
    required WordLocalDataSource wordLocal,
  })  : _authRepo = authRepo,
        _progressLocal = progressLocal,
        _progressRemote = progressRemote,
        _wordRemote = wordRemote,
        _wordLocal = wordLocal,
        super(const FlashcardsInitial()) {
    on<FlashcardsStartRequested>(_onStartRequested);
    on<FlashcardsCardFlipRequested>(_onCardFlipRequested);
    on<FlashcardsAnswerSubmitted>(_onAnswerSubmitted);
    on<FlashcardsSessionRestarted>(_onSessionRestarted);
  }

  final AuthRepository _authRepo;
  final ProgressLocalDataSource _progressLocal;
  final ProgressRemoteDataSource _progressRemote;
  final WordRemoteDataSource _wordRemote;
  final WordLocalDataSource _wordLocal;

  // ─── Event handlers ──────────────────────────────────────────────────────────

  Future<void> _onStartRequested(
    FlashcardsStartRequested event,
    Emitter<FlashcardsState> emit,
  ) async {
    emit(const FlashcardsLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyGoal = prefs.getInt(AppConstants.keyDailyGoal) ?? 5;
      final userLevel = prefs.getString(AppConstants.keyUserLevel) ?? 'a1';
      final isGuest = prefs.getBool(AppConstants.keyGuestMode) ?? false;
      final uiLanguage = prefs.getString(AppConstants.keyUiLanguage) ?? 'ru';
      final userId = _authRepo.currentUserId;
      final isAuth = !isGuest && userId != null;

      final List<FlashcardItem> queue;

      if (isAuth) {
        queue = await _buildRemoteQueue(
          userId: userId,
          dailyGoal: dailyGoal,
          userLevel: userLevel,
        );
      } else {
        queue = await _buildLocalQueue(
          dailyGoal: dailyGoal,
          userLevel: userLevel,
        );
      }

      if (!isClosed) {
        if (queue.isEmpty) {
          emit(const FlashcardsEmpty());
        } else {
          emit(
            FlashcardsActive(
              queue: queue,
              currentIndex: 0,
              isFlipped: false,
              stats: const FlashcardsSessionStats(),
              uiLanguage: uiLanguage,
              isGuest: isGuest,
              userId: userId ?? '',
            ),
          );
        }
      }
    } on Object catch (e, st) {
      debugPrint('[FlashcardsBloc] start error: $e\n$st');
      if (!isClosed) emit(FlashcardsError(e.toString()));
    }
  }

  void _onCardFlipRequested(
    FlashcardsCardFlipRequested event,
    Emitter<FlashcardsState> emit,
  ) {
    final s = state;
    if (s is! FlashcardsActive || s.isFlipped) return;
    emit(s.copyWith(isFlipped: true));
  }

  Future<void> _onAnswerSubmitted(
    FlashcardsAnswerSubmitted event,
    Emitter<FlashcardsState> emit,
  ) async {
    final s = state;
    if (s is! FlashcardsActive) return;

    final current = s.current;
    final newStats = event.knew ? s.stats.withKnew() : s.stats.withDidntKnow();

    // Save progress (fire and forget remote)
    unawaited(
      _saveProgress(
        wordId: current.word.id,
        userId: s.userId,
        knew: event.knew,
        currentEaseFactor: current.easeFactor,
        currentRepetitions: current.repetitions,
        isGuest: s.isGuest,
      ),
    );

    if (!isClosed) {
      if (s.isLast) {
        emit(FlashcardsSessionComplete(stats: newStats));
      } else {
        emit(
          s.copyWith(
            currentIndex: s.currentIndex + 1,
            isFlipped: false,
            stats: newStats,
          ),
        );
      }
    }
  }

  void _onSessionRestarted(
    FlashcardsSessionRestarted event,
    Emitter<FlashcardsState> emit,
  ) {
    add(const FlashcardsStartRequested());
  }

  // ─── Queue building ──────────────────────────────────────────────────────────

  Future<List<FlashcardItem>> _buildRemoteQueue({
    required String userId,
    required int dailyGoal,
    required String userLevel,
  }) async {
    // 1. Due review words
    final dueEntries = await _progressRemote.fetchDueProgressEntries(userId);
    final List<FlashcardItem> reviewItems;

    if (dueEntries.isNotEmpty) {
      final dueWordIds = dueEntries.map((e) => e['word_id'] as String).toList();
      final result = await _wordRemote.fetchPage(
        inIds: dueWordIds,
        offset: 0,
        limit: dueWordIds.length,
      );
      final progressByWordId = {
        for (final e in dueEntries) e['word_id'] as String: e,
      };
      reviewItems = result.words.map((w) {
        final p = progressByWordId[w.id] ?? const <String, dynamic>{};
        return FlashcardItem(
          word: w,
          easeFactor:
              (p['ease_factor'] as num?)?.toDouble() ??
              AppConstants.sm2DefaultEaseFactor,
          repetitions: p['repetitions'] as int? ?? 0,
          isReview: true,
        );
      }).toList();
    } else {
      reviewItems = [];
    }

    // 2. New words (fill remaining slots in daily goal)
    final stats = await _progressRemote.fetchProgressStats(userId);
    final todayReviewed = stats['today_reviewed'] ?? 0;
    final newSlots =
        (dailyGoal - todayReviewed - reviewItems.length).clamp(0, dailyGoal);

    final List<FlashcardItem> newItems;

    if (newSlots > 0) {
      final allProgressIds =
          await _progressRemote.fetchAllProgressWordIds(userId);
      final level = _parseLevel(userLevel);
      final result = await _wordRemote.fetchPage(
        excludeIds: allProgressIds.isEmpty ? null : allProgressIds,
        level: level,
        offset: 0,
        limit: newSlots,
      );
      newItems = result.words
          .map(
            (w) => FlashcardItem(
              word: w,
              easeFactor: AppConstants.sm2DefaultEaseFactor,
              repetitions: 0,
              isReview: false,
            ),
          )
          .toList();
    } else {
      newItems = [];
    }

    return [...reviewItems, ...newItems];
  }

  Future<List<FlashcardItem>> _buildLocalQueue({
    required int dailyGoal,
    required String userLevel,
  }) async {
    // 1. Due review words from Hive
    final dueEntries = await _progressLocal.getDueProgressEntries();
    final List<FlashcardItem> reviewItems;

    if (dueEntries.isNotEmpty) {
      final dueWordIds = dueEntries.map((e) => e['word_id'] as String).toList();
      final progressByWordId = {
        for (final e in dueEntries) e['word_id'] as String: e,
      };
      // Fetch cached words matching due IDs
      final result = await _wordLocal.fetchPage(
        offset: 0,
        limit: dueWordIds.length + 1,
      );
      final dueWords = result.words.where((w) => dueWordIds.contains(w.id));
      reviewItems = dueWords.map((w) {
        final p = progressByWordId[w.id] ?? const <String, dynamic>{};
        return FlashcardItem(
          word: w,
          easeFactor:
              (p['ease_factor'] as num?)?.toDouble() ??
              AppConstants.sm2DefaultEaseFactor,
          repetitions: p['repetitions'] as int? ?? 0,
          isReview: true,
        );
      }).toList();
    } else {
      reviewItems = [];
    }

    // 2. New words from cache
    final allProgressIds = await _progressLocal.getAllProgressWordIds();
    final newSlots =
        (dailyGoal - reviewItems.length).clamp(0, dailyGoal);

    final List<FlashcardItem> newItems;

    if (newSlots > 0) {
      final result = await _wordLocal.fetchPage(
        offset: 0,
        limit: newSlots,
        level: _parseLevel(userLevel),
        statusFilter: 'newWord',
      );
      newItems = result.words
          .where((w) => !allProgressIds.contains(w.id))
          .map(
            (w) => FlashcardItem(
              word: w,
              easeFactor: AppConstants.sm2DefaultEaseFactor,
              repetitions: 0,
              isReview: false,
            ),
          )
          .toList();
    } else {
      newItems = [];
    }

    return [...reviewItems, ...newItems];
  }

  // ─── Progress saving ─────────────────────────────────────────────────────────

  Future<void> _saveProgress({
    required String wordId,
    required String userId,
    required bool knew,
    required double currentEaseFactor,
    required int currentRepetitions,
    required bool isGuest,
  }) async {
    final data = _calculateSm2(
      wordId: wordId,
      userId: userId,
      knew: knew,
      easeFactor: currentEaseFactor,
      repetitions: currentRepetitions,
    );

    await _progressLocal.saveProgressEntry(wordId: wordId, data: data);

    if (!isGuest) {
      try {
        await _progressRemote.upsertProgressEntry(data);
      } on Object catch (e, st) {
        debugPrint(
          '[FlashcardsBloc] remote progress save failed (non-fatal): $e\n$st',
        );
      }
    }
  }

  Map<String, dynamic> _calculateSm2({
    required String wordId,
    required String userId,
    required bool knew,
    required double easeFactor,
    required int repetitions,
  }) {
    final now = DateTime.now();

    if (!knew) {
      return {
        'word_id': wordId,
        'user_id': userId,
        'status': 'learning',
        'repetitions': 0,
        'ease_factor': (easeFactor - 0.2).clamp(
          AppConstants.sm2MinEaseFactor,
          double.infinity,
        ),
        'next_review_at':
            now.add(const Duration(hours: 1)).toIso8601String(),
        'last_reviewed_at': now.toIso8601String(),
      };
    }

    final newRepetitions = repetitions + 1;
    final interval = switch (newRepetitions) {
      1 => AppConstants.sm2FirstInterval,
      2 => AppConstants.sm2SecondInterval,
      _ => (easeFactor * (newRepetitions - 1)).round(),
    };

    final newEaseFactor = (easeFactor + 0.1).clamp(
      AppConstants.sm2MinEaseFactor,
      double.infinity,
    );

    return {
      'word_id': wordId,
      'user_id': userId,
      'status': interval >= 21 ? 'known' : 'learning',
      'repetitions': newRepetitions,
      'ease_factor': newEaseFactor,
      'next_review_at':
          now.add(Duration(days: interval)).toIso8601String(),
      'last_reviewed_at': now.toIso8601String(),
    };
  }

  WordLevel _parseLevel(String value) {
    final lower = value.toLowerCase();
    return WordLevel.values.firstWhere(
      (l) => l.name == lower,
      orElse: () => WordLevel.a1,
    );
  }
}
