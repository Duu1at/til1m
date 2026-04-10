import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/network/connectivity_service.dart';
import 'package:til1m/data/datasources/local/flashcard_local_datasource.dart';
import 'package:til1m/data/datasources/remote/flashcard_remote_datasource.dart';
import 'package:til1m/data/datasources/sync/progress_sync_service.dart';
import 'package:til1m/data/models/flashcard_session_model.dart';
import 'package:til1m/domain/entities/flashcard_session.dart';
import 'package:til1m/domain/entities/user_progress.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/entities/word_progress.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/domain/repositories/progress_repository.dart';
import 'package:til1m/domain/usecases/calculate_sm2.dart';

WordProgress _progressFromEntity(UserWordProgress p) => WordProgress(
  wordId: p.wordId,
  status: p.status,
  easeFactor: p.easeFactor,
  repetitions: p.repetitions,
  nextReviewAt: p.nextReviewAt,
  lastReviewedAt: p.lastReviewedAt,
);

/// Implements [ProgressRepository] with online/guest dual mode:
///
/// - **Authenticated** → Supabase as primary, Hive as write-through cache.
/// - **Guest** → Hive only; progress synced to Supabase on account creation.
///
/// Every Supabase call is wrapped in try/catch; on network failure the method
/// falls back to the local cache and logs the error via [debugPrint].
@immutable
class FlashcardRepositoryImpl implements ProgressRepository {
  const FlashcardRepositoryImpl({
    required FlashcardRemoteDataSource remote,
    required FlashcardLocalDataSource local,
    required AuthRepository authRepo,
    required ConnectivityService connectivity,
    required ProgressSyncService syncService,
  }) : _remote = remote,
       _local = local,
       _authRepo = authRepo,
       _connectivity = connectivity,
       _syncService = syncService;

  final FlashcardRemoteDataSource _remote;
  final FlashcardLocalDataSource _local;
  final AuthRepository _authRepo;
  final ConnectivityService _connectivity;
  final ProgressSyncService _syncService;

  static const _sm2 = CalculateSm2();

  bool get _isAuth => !_authRepo.isGuest && _authRepo.currentUserId != null;

  // ─── Review queue ─────────────────────────────────────────────────────────────

  @override
  Future<List<UserWordProgress>> getTodayReviewQueue(String userId) async {
    if (_isAuth) {
      try {
        final pairs = await _remote.getWordsForReview(
          userId: userId,
          limit: 50,
        );
        // Cache word data locally for offline use.
        unawaited(_local.cacheWords(pairs.map((p) => p.word).toList()));
        return pairs.map((p) => p.progress).toList();
      } on Object catch (e, st) {
        debugPrint(
          '[FlashcardRepo] getTodayReviewQueue remote failed: $e\n$st',
        );
        // Fall through to local cache.
      }
    }

    // Guest or offline fallback.
    final localProgress = await _local.getDueProgress();
    return localProgress
        .map(
          (p) => UserWordProgress(
            id: '${userId}_${p.wordId}',
            userId: userId,
            wordId: p.wordId,
            status: p.status,
            easeFactor: p.easeFactor,
            repetitions: p.repetitions,
            nextReviewAt: p.nextReviewAt,
            lastReviewedAt: p.lastReviewedAt,
          ),
        )
        .toList();
  }

  @override
  Future<List<UserWordProgress>> getNewWordsQueue(
    String userId,
    WordLevel level,
    int limit,
  ) async {
    // New words have no progress entries yet — this method intentionally returns
    // empty. Use WordRepository.getWords(level: level) combined with
    // getProgressWordIds() to build the new-word queue in the BLoC layer.
    return [];
  }

  // ─── Single progress entry ────────────────────────────────────────────────────

  @override
  Future<UserWordProgress?> getWordProgress(
    String userId,
    String wordId,
  ) async {
    if (_isAuth) {
      try {
        return await _remote.getProgressForWord(
          userId: userId,
          wordId: wordId,
        );
      } on Object catch (e, st) {
        debugPrint('[FlashcardRepo] getWordProgress remote failed: $e\n$st');
      }
    }

    final local = await _local.getProgressForWord(wordId);
    if (local == null) return null;
    return UserWordProgress(
      id: '${userId}_$wordId',
      userId: userId,
      wordId: local.wordId,
      status: local.status,
      easeFactor: local.easeFactor,
      repetitions: local.repetitions,
      nextReviewAt: local.nextReviewAt,
      lastReviewedAt: local.lastReviewedAt,
    );
  }

  @override
  Future<void> saveProgress(UserWordProgress progress) async {
    // Always write to local Hive cache — works in all modes.
    await _local.saveProgress(
      WordProgress(
        wordId: progress.wordId,
        status: progress.status,
        easeFactor: progress.easeFactor,
        repetitions: progress.repetitions,
        nextReviewAt: progress.nextReviewAt,
        lastReviewedAt: progress.lastReviewedAt,
      ),
    );

    if (_isAuth) {
      if (_connectivity.isOnline) {
        try {
          await _remote.saveProgress(progress);
          // Remove any previously queued pending entry for this word.
          unawaited(
            _syncService.removePending(
              userId: progress.userId,
              wordId: progress.wordId,
            ),
          );
        } on Object catch (e, st) {
          debugPrint(
            '[FlashcardRepo] saveProgress remote failed — queuing: $e\n$st',
          );
          await _syncService.addPending(progress);
        }
      } else {
        // Offline — queue for later upload.
        await _syncService.addPending(progress);
      }
    }
  }

  // ─── SM-2 application ─────────────────────────────────────────────────────────

  @override
  Future<void> applySmResult({
    required String userId,
    required String wordId,
    required bool knew,
  }) async {
    final existing = await getWordProgress(userId, wordId);

    final current = existing != null
        ? WordProgress(
            wordId: wordId,
            status: existing.status,
            easeFactor: existing.easeFactor,
            repetitions: existing.repetitions,
            nextReviewAt: existing.nextReviewAt,
            lastReviewedAt: existing.lastReviewedAt,
          )
        : WordProgress(wordId: wordId);

    final result = _sm2.calculate(current: current, isCorrect: knew);

    await saveProgress(
      UserWordProgress(
        id: '${userId}_$wordId',
        userId: userId,
        wordId: wordId,
        status: result.updatedProgress.status,
        easeFactor: result.updatedProgress.easeFactor,
        repetitions: result.updatedProgress.repetitions,
        nextReviewAt: result.updatedProgress.nextReviewAt,
        lastReviewedAt: result.updatedProgress.lastReviewedAt,
      ),
    );
  }

  // ─── Statistics ───────────────────────────────────────────────────────────────

  @override
  Future<int> getKnownWordsCount(String userId) async {
    final stats = await _fetchStats(userId);
    return stats['known'] ?? 0;
  }

  @override
  Future<int> getTodayLearnedCount(String userId) async {
    final stats = await _fetchStats(userId);
    return stats['today_reviewed'] ?? 0;
  }

  @override
  Future<Map<String, int>> getProgressByLevel(String userId) async {
    if (_isAuth) {
      try {
        return await _remote.fetchProgressByLevel(userId);
      } on Object catch (e, st) {
        debugPrint(
          '[FlashcardRepo] getProgressByLevel remote failed: $e\n$st',
        );
      }
    }
    return _local.fetchProgressByLevel();
  }

  @override
  Future<void> syncLocalToRemote(String userId) async {
    try {
      final localProgress = await _local.getAllProgress();
      if (localProgress.isEmpty) return;

      final remoteEntries = localProgress
          .map(
            (p) => UserWordProgress(
              id: '${userId}_${p.wordId}',
              userId: userId,
              wordId: p.wordId,
              status: p.status,
              easeFactor: p.easeFactor,
              repetitions: p.repetitions,
              nextReviewAt: p.nextReviewAt,
              lastReviewedAt: p.lastReviewedAt,
            ),
          )
          .toList();

      await _remote.bulkSaveProgress(remoteEntries);
      debugPrint(
        '[FlashcardRepo] syncLocalToRemote: uploaded ${remoteEntries.length} entries',
      );
    } on Object catch (e, st) {
      debugPrint('[FlashcardRepo] syncLocalToRemote error: $e\n$st');
      rethrow;
    }
  }

  Future<void> saveSession(FlashcardSession session) async {
    await _local.saveSessionState(FlashcardSessionModel.fromSession(session));
  }

  Future<FlashcardSession?> restoreSession() async {
    final model = await _local.getSessionState();
    if (model == null) return null;
    final wordCache = await _local.getCachedWordMap(model.wordIds);
    return model.toSession(wordCache);
  }

  Future<void> clearSession() => _local.clearSessionState();

  Future<List<FlashcardSessionItem>> getReviewSessionItems(
    String userId,
  ) async {
    if (_isAuth) {
      try {
        final pairs = await _remote.getWordsForReview(
          userId: userId,
          limit: 50,
        );
        unawaited(_local.cacheWords(pairs.map((p) => p.word).toList()));
        return pairs.map((p) {
          return FlashcardSessionItem(
            word: p.word,
            progress: _progressFromEntity(p.progress),
            isReview: true,
          );
        }).toList();
      } on Object catch (e, st) {
        debugPrint(
          '[FlashcardRepo] getReviewSessionItems remote failed: $e\n$st',
        );
      }
    }

    final dueProgress = await _local.getDueProgress();
    if (dueProgress.isEmpty) return [];
    final wordIds = dueProgress.map((p) => p.wordId).toList();
    final wordMap = await _local.getCachedWordMap(wordIds);

    final items = <FlashcardSessionItem>[];
    for (final p in dueProgress) {
      final word = wordMap[p.wordId];
      if (word == null) continue;
      items.add(FlashcardSessionItem(word: word, progress: p, isReview: true));
    }
    return items;
  }

  Future<List<String>> getProgressWordIds(String userId) async {
    if (_isAuth) {
      try {
        return await _remote.getProgressWordIds(userId);
      } on Object catch (e, st) {
        debugPrint(
          '[FlashcardRepo] getProgressWordIds remote failed: $e\n$st',
        );
      }
    }
    return _local.getAllProgressWordIds();
  }

  Future<List<Word>> getNewWords({
    required WordLevel level,
    required List<String> excludeIds,
    int limit = AppConstants.sm2SecondInterval,
  }) async {
    if (_isAuth) {
      try {
        final words = await _remote.getWordsByLevel(
          level: level,
          excludeIds: excludeIds,
          limit: limit,
        );
        unawaited(_local.cacheWords(words));
        return words;
      } on Object catch (e, st) {
        debugPrint('[FlashcardRepo] getNewWords remote failed: $e\n$st');
      }
    }
    return _local.getCachedWords(
      level: level,
      excludeIds: excludeIds,
      limit: limit,
    );
  }

  Future<Map<String, int>> _fetchStats(String userId) async {
    if (_isAuth) {
      try {
        return await _remote.fetchProgressStats(userId);
      } on Object catch (e, st) {
        debugPrint('[FlashcardRepo] fetchStats remote failed: $e\n$st');
      }
    }
    return _local.fetchProgressStats();
  }
}
