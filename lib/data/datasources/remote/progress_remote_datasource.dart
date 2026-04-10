import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/constants/supabase_constants.dart';
import 'package:til1m/domain/entities/user_progress.dart';
import 'package:til1m/domain/entities/word_progress.dart';

class ProgressRemoteDataSource {
  ProgressRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchDueProgressEntries(
    String userId,
  ) async {
    try {
      final data = await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select(
            'word_id, ease_factor, repetitions, status, next_review_at, last_reviewed_at',
          )
          .eq('user_id', userId)
          .lte('next_review_at', DateTime.now().toIso8601String());
      return data.map(Map<String, dynamic>.from).toList();
    } on Object catch (e, st) {
      debugPrint('[ProgressRemote] fetchDueProgressEntries error: $e\n$st');
      rethrow;
    }
  }

  Future<List<String>> fetchAllProgressWordIds(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select('word_id')
          .eq('user_id', userId);
      return data.map((r) => r['word_id'] as String).toList();
    } on Object catch (e, st) {
      debugPrint('[ProgressRemote] fetchAllProgressWordIds error: $e\n$st');
      rethrow;
    }
  }

  Future<void> upsertProgressEntry(Map<String, dynamic> data) async {
    try {
      await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .upsert(data, onConflict: 'user_id,word_id');
    } on Object catch (e, st) {
      debugPrint('[ProgressRemote] upsertProgressEntry error: $e\n$st');
      rethrow;
    }
  }

  Future<WordProgress?> fetchProgressForWord({
    required String userId,
    required String wordId,
  }) async {
    try {
      final data = await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select(
            'word_id, ease_factor, repetitions, status, next_review_at, last_reviewed_at',
          )
          .eq('user_id', userId)
          .eq('word_id', wordId)
          .maybeSingle();
      if (data == null) return null;
      return WordProgress(
        wordId: data['word_id'] as String,
        status: _parseStatus(data['status'] as String?),
        easeFactor: (data['ease_factor'] as num?)?.toDouble() ?? 2.5,
        repetitions: data['repetitions'] as int? ?? 0,
        nextReviewAt: _parseDate(data['next_review_at'] as String?),
        lastReviewedAt: _parseDate(data['last_reviewed_at'] as String?),
      );
    } on Object catch (e, st) {
      debugPrint('[ProgressRemote] fetchProgressForWord error: $e\n$st');
      rethrow;
    }
  }

  Future<void> syncProgress(WordProgress progress, String userId) async {
    try {
      await upsertProgressEntry({
        'user_id': userId,
        'word_id': progress.wordId,
        'status': _statusStr(progress.status),
        'ease_factor': progress.easeFactor,
        'repetitions': progress.repetitions,
        'next_review_at': progress.nextReviewAt?.toIso8601String(),
        'last_reviewed_at': progress.lastReviewedAt?.toIso8601String(),
      });
    } on Object catch (e, st) {
      debugPrint('[ProgressRemote] syncProgress error: $e\n$st');
      rethrow;
    }
  }

  Future<void> syncFavorite({
    required String userId,
    required String wordId,
    required bool add,
  }) async {
    try {
      if (add) {
        await _client
            .from(SupabaseConstants.tableUserFavorites)
            .upsert({'user_id': userId, 'word_id': wordId});
      } else {
        await _client
            .from(SupabaseConstants.tableUserFavorites)
            .delete()
            .eq('user_id', userId)
            .eq('word_id', wordId);
      }
    } on Object catch (e, st) {
      debugPrint('[ProgressRemote] syncFavorite error: $e\n$st');
      rethrow;
    }
  }

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

  Future<Map<String, int>> fetchProgressStats(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select('status, last_reviewed_at, next_review_at')
          .eq('user_id', userId);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      var knownCount = 0;
      var learningCount = 0;
      var todayReviewed = 0;
      var dueCount = 0;

      for (final row in data) {
        final status = row['status'] as String? ?? '';
        if (status == 'known') knownCount++;
        if (status == 'learning') learningCount++;

        final lastStr = row['last_reviewed_at'] as String?;
        if (lastStr != null) {
          final dt = DateTime.tryParse(lastStr);
          if (dt != null && dt.isAfter(todayStart)) todayReviewed++;
        }

        final nextStr = row['next_review_at'] as String?;
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
      debugPrint('[ProgressRemote] fetchProgressStats error: $e\n$st');
      rethrow;
    }
  }
}
