import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/domain/entities/user_progress.dart';
import 'package:til1m/domain/entities/word_progress.dart';

class ProgressLocalDataSource {
  Future<Box<dynamic>> _progressBox() async {
    return Hive.isBoxOpen(AppConstants.hiveBoxProgress)
        ? Hive.box<dynamic>(AppConstants.hiveBoxProgress)
        : Hive.openBox<dynamic>(AppConstants.hiveBoxProgress);
  }

  Future<List<Map<String, dynamic>>> getDueProgressEntries() async {
    try {
      final box = await _progressBox();
      final now = DateTime.now();
      final result = <Map<String, dynamic>>[];

      for (final value in box.values) {
        if (value is! Map) continue;
        final nextStr = value['next_review_at'] as String?;
        if (nextStr == null) {
          result.add(Map<String, dynamic>.from(value));
          continue;
        }
        final dt = DateTime.tryParse(nextStr);
        if (dt != null && !dt.isAfter(now)) {
          result.add(Map<String, dynamic>.from(value));
        }
      }

      return result;
    } on Object catch (e, st) {
      debugPrint('[ProgressLocal] getDueProgressEntries error: $e\n$st');
      return [];
    }
  }

  Future<List<String>> getAllProgressWordIds() async {
    try {
      final box = await _progressBox();
      final ids = <String>[];

      for (final entry in box.toMap().entries) {
        final value = entry.value;
        if (value is! Map) continue;
        final wordId =
            value['word_id'] as String? ?? entry.key as String? ?? '';
        if (wordId.isNotEmpty) ids.add(wordId);
      }

      return ids;
    } on Object catch (e, st) {
      debugPrint('[ProgressLocal] getAllProgressWordIds error: $e\n$st');
      return [];
    }
  }

  Future<void> saveProgressEntry({
    required String wordId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final box = await _progressBox();
      await box.put(wordId, data);
    } on Object catch (e, st) {
      debugPrint('[ProgressLocal] saveProgressEntry error: $e\n$st');
    }
  }

  /// Returns the locally-cached [WordProgress] for [wordId], or null.
  Future<WordProgress?> getProgressForWord(String wordId) async {
    try {
      final box = await _progressBox();
      final raw = box.get(wordId);
      if (raw is! Map) return null;
      final data = Map<String, dynamic>.from(raw);
      return WordProgress(
        wordId: wordId,
        status: _parseStatus(data['status'] as String?),
        easeFactor: (data['ease_factor'] as num?)?.toDouble() ?? 2.5,
        repetitions: data['repetitions'] as int? ?? 0,
        nextReviewAt: _parseDate(data['next_review_at'] as String?),
        lastReviewedAt: _parseDate(data['last_reviewed_at'] as String?),
      );
    } on Object catch (e, st) {
      debugPrint('[ProgressLocal] getProgressForWord error: $e\n$st');
      return null;
    }
  }

  /// Persists a [WordProgress] to the local Hive cache.
  Future<void> saveProgress(WordProgress progress) async {
    await saveProgressEntry(
      wordId: progress.wordId,
      data: {
        'word_id': progress.wordId,
        'status': _statusStr(progress.status),
        'ease_factor': progress.easeFactor,
        'repetitions': progress.repetitions,
        'next_review_at': progress.nextReviewAt?.toIso8601String(),
        'last_reviewed_at': progress.lastReviewedAt?.toIso8601String(),
      },
    );
  }

  // ─── Favorites ────────────────────────────────────────────────────────────────

  Future<Box<dynamic>> _favoritesBox() async =>
      Hive.isBoxOpen(AppConstants.hiveBoxFavorites)
          ? Hive.box<dynamic>(AppConstants.hiveBoxFavorites)
          : Hive.openBox<dynamic>(AppConstants.hiveBoxFavorites);

  Future<bool> isFavorite(String wordId) async {
    try {
      final box = await _favoritesBox();
      return box.containsKey(wordId);
    } on Object catch (e, st) {
      debugPrint('[ProgressLocal] isFavorite error: $e\n$st');
      return false;
    }
  }

  Future<void> setFavorite(String wordId, {required bool add}) async {
    try {
      final box = await _favoritesBox();
      if (add) {
        await box.put(wordId, true);
      } else {
        await box.delete(wordId);
      }
    } on Object catch (e, st) {
      debugPrint('[ProgressLocal] setFavorite error: $e\n$st');
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static WordStatus _parseStatus(String? value) => switch (value) {
    'learning' => WordStatus.learning,
    'known' => WordStatus.known,
    _ => WordStatus.newWord,
  };

  static String _statusStr(WordStatus status) => switch (status) {
    WordStatus.newWord => 'new',
    WordStatus.learning => 'learning',
    WordStatus.known => 'known',
  };

  static DateTime? _parseDate(String? value) =>
      value != null ? DateTime.tryParse(value) : null;

  Future<Map<String, int>> fetchProgressStats() async {
    try {
      final box = await _progressBox();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      var knownCount = 0;
      var learningCount = 0;
      var todayReviewed = 0;
      var dueCount = 0;

      for (final value in box.values) {
        if (value is! Map) continue;
        final status = value['status'] as String? ?? '';
        if (status == 'known') knownCount++;
        if (status == 'learning') learningCount++;

        final lastStr = value['last_reviewed_at'] as String?;
        if (lastStr != null) {
          final dt = DateTime.tryParse(lastStr);
          if (dt != null && dt.isAfter(todayStart)) todayReviewed++;
        }

        final nextStr = value['next_review_at'] as String?;
        if (nextStr != null) {
          final dt = DateTime.tryParse(nextStr);
          if (dt != null && !dt.isAfter(now)) dueCount++;
        }
      }

      return {
        'known': knownCount,
        'learning': learningCount,
        'today_reviewed': todayReviewed,
        'due': dueCount,
      };
    } on Object catch (e, st) {
      debugPrint('[ProgressLocal] fetchProgressStats error: $e\n$st');
      return {'known': 0, 'learning': 0, 'today_reviewed': 0, 'due': 0};
    }
  }
}
