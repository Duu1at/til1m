import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/constants/supabase_constants.dart';
import 'package:til1m/data/models/user_word_progress_model.dart';
import 'package:til1m/data/models/word_model.dart';
import 'package:til1m/domain/entities/user_progress.dart';
import 'package:til1m/domain/entities/word.dart';

class FlashcardRemoteDataSource {
  const FlashcardRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _wordSelect = '''
    id, word, level, part_of_speech, transcription_text,
    audio_url, image_url, created_at,
    word_translations(language, translation, synonyms),
    word_examples(example_en, example_ru, example_ky, order_index)
  ''';

  // ─── Words ────────────────────────────────────────────────────────────────────

  /// Returns words that are due for review, paired with their SM-2 progress.
  ///
  /// Uses two queries: one for due progress entries, one for the matching words.
  Future<List<({Word word, UserWordProgress progress})>> getWordsForReview({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final progressRows = await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select(
            'word_id, ease_factor, repetitions, status, next_review_at, last_reviewed_at',
          )
          .eq('user_id', userId)
          .lte('next_review_at', DateTime.now().toIso8601String())
          .limit(limit);

      if (progressRows.isEmpty) return [];

      final wordIds =
          progressRows.map((p) => p['word_id'] as String).toList();

      final wordsRows = await _client
          .from(SupabaseConstants.tableWords)
          .select(_wordSelect)
          .inFilter('id', wordIds);

      final wordMap = <String, Word>{
        for (final row in wordsRows.map(WordModel.fromJson)) row.id: row,
      };
      final progressById = <String, Map<String, dynamic>>{
        for (final p in progressRows)
          p['word_id'] as String: Map<String, dynamic>.from(p),
      };

      final result = <({Word word, UserWordProgress progress})>[];
      for (final wordId in wordIds) {
        final word = wordMap[wordId];
        final pData = progressById[wordId];
        if (word == null || pData == null) continue;

        final progress = UserWordProgressModel.fromJson({
          ...pData,
          'user_id': userId,
        }).toEntity();

        result.add((word: word, progress: progress));
      }
      return result;
    } on Object catch (e, st) {
      debugPrint('[FlashcardRemote] getWordsForReview error: $e\n$st');
      rethrow;
    }
  }

  /// Returns new words at [level], excluding [excludeIds].
  Future<List<Word>> getWordsByLevel({
    required WordLevel level,
    List<String> excludeIds = const [],
    int limit = 10,
  }) async {
    try {
      var q = _client
          .from(SupabaseConstants.tableWords)
          .select(_wordSelect)
          .eq('level', level.name.toUpperCase());

      if (excludeIds.isNotEmpty) {
        q = q.not('id', 'in', '(${excludeIds.join(',')})');
      }

      final data = await q.order('word').limit(limit);
      return data.map<Word>(WordModel.fromJson).toList();
    } on Object catch (e, st) {
      debugPrint('[FlashcardRemote] getWordsByLevel error: $e\n$st');
      rethrow;
    }
  }

  // ─── Progress ─────────────────────────────────────────────────────────────────

  /// Returns word IDs that already have a progress entry for [userId].
  Future<List<String>> getProgressWordIds(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select('word_id')
          .eq('user_id', userId);
      return data.map((r) => r['word_id'] as String).toList();
    } on Object catch (e, st) {
      debugPrint('[FlashcardRemote] getProgressWordIds error: $e\n$st');
      rethrow;
    }
  }

  Future<UserWordProgress?> getProgressForWord({
    required String userId,
    required String wordId,
  }) async {
    try {
      final data = await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select()
          .eq('user_id', userId)
          .eq('word_id', wordId)
          .maybeSingle();
      if (data == null) return null;
      return UserWordProgressModel.fromJson(
        Map<String, dynamic>.from(data),
      ).toEntity();
    } on Object catch (e, st) {
      debugPrint('[FlashcardRemote] getProgressForWord error: $e\n$st');
      rethrow;
    }
  }

  /// Upserts [progress] into `user_word_progress`.
  Future<void> saveProgress(UserWordProgress progress) async {
    try {
      await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .upsert(
            UserWordProgressModel.fromEntity(progress).toJson(),
            onConflict: 'user_id,word_id',
          );
    } on Object catch (e, st) {
      debugPrint('[FlashcardRemote] saveProgress error: $e\n$st');
      rethrow;
    }
  }

  /// Bulk-upserts [progressList] — used during guest → account sync.
  Future<void> bulkSaveProgress(List<UserWordProgress> progressList) async {
    if (progressList.isEmpty) return;
    try {
      final rows = progressList
          .map((p) => UserWordProgressModel.fromEntity(p).toJson())
          .toList();
      await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .upsert(rows, onConflict: 'user_id,word_id');
    } on Object catch (e, st) {
      debugPrint('[FlashcardRemote] bulkSaveProgress error: $e\n$st');
      rethrow;
    }
  }

  // ─── Statistics ───────────────────────────────────────────────────────────────

  Future<Map<String, int>> fetchProgressStats(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select('status, last_reviewed_at, next_review_at')
          .eq('user_id', userId);
      return _aggregateStats(data.map(Map<String, dynamic>.from).toList());
    } on Object catch (e, st) {
      debugPrint('[FlashcardRemote] fetchProgressStats error: $e\n$st');
      rethrow;
    }
  }

  /// Counts progress entries grouped by word level (requires a word JOIN).
  Future<Map<String, int>> fetchProgressByLevel(String userId) async {
    try {
      final progressIds = await getProgressWordIds(userId);
      if (progressIds.isEmpty) return {};

      final wordsData = await _client
          .from(SupabaseConstants.tableWords)
          .select('id, level')
          .inFilter('id', progressIds);

      final counts = <String, int>{};
      for (final row in wordsData) {
        final level = (row['level'] as String?)?.toLowerCase() ?? 'a1';
        counts[level] = (counts[level] ?? 0) + 1;
      }
      return counts;
    } on Object catch (e, st) {
      debugPrint('[FlashcardRemote] fetchProgressByLevel error: $e\n$st');
      rethrow;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  static Map<String, int> _aggregateStats(List<Map<String, dynamic>> rows) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    var known = 0;
    var learning = 0;
    var todayReviewed = 0;
    var due = 0;

    for (final row in rows) {
      switch (row['status'] as String?) {
        case 'known':
          known++;
        case 'learning':
          learning++;
      }

      final lastStr = row['last_reviewed_at'] as String?;
      if (lastStr != null) {
        final dt = DateTime.tryParse(lastStr);
        if (dt != null && dt.isAfter(todayStart)) todayReviewed++;
      }

      final nextStr = row['next_review_at'] as String?;
      if (nextStr != null) {
        final dt = DateTime.tryParse(nextStr);
        if (dt != null && !dt.isAfter(now)) due++;
      }
    }

    return {
      'known': known,
      'learning': learning,
      'today_reviewed': todayReviewed,
      'due': due,
    };
  }
}
