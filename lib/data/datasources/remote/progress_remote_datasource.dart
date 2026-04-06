import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/constants/supabase_constants.dart';

class ProgressRemoteDataSource {
  ProgressRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Returns progress rows where next_review_at <= now (due for review).
  Future<List<Map<String, dynamic>>> fetchDueProgressEntries(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select('word_id, ease_factor, repetitions, status, next_review_at, last_reviewed_at')
          .eq('user_id', userId)
          .lte('next_review_at', DateTime.now().toIso8601String());
      return data.map(Map<String, dynamic>.from).toList();
    } on Object catch (e, st) {
      debugPrint('[ProgressRemote] fetchDueProgressEntries error: $e\n$st');
      rethrow;
    }
  }

  /// Returns all word IDs that the user has any progress for.
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

  /// Upserts a progress entry. [data] must contain user_id, word_id, status,
  /// ease_factor, repetitions, next_review_at, last_reviewed_at.
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
