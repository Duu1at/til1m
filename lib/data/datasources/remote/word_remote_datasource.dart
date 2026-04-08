import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/constants/supabase_constants.dart';
import 'package:til1m/data/models/word_model.dart';
import 'package:til1m/domain/entities/word.dart';

class WordRemoteDataSource {
  WordRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _wordSelect = '''
    id, word, level, part_of_speech, transcription_text,
    audio_url, image_url, created_at,
    word_translations(language, translation, synonyms),
    word_examples(example_en, example_ru, example_ky, order_index)
  ''';

  Future<({List<Word> words, bool hasMore})> fetchPage({
    required int offset,
    required int limit,
    String? searchQuery,
    WordLevel? level,
    List<String>? inIds,
    List<String>? excludeIds,
    bool sortByLevel = false,
  }) async {
    try {
      var q = _client.from(SupabaseConstants.tableWords).select(_wordSelect);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        q = q.ilike('word', '%$searchQuery%');
      }
      if (level != null) {
        q = q.eq('level', level.name.toUpperCase());
      }
      if (inIds != null && inIds.isNotEmpty) {
        q = q.inFilter('id', inIds);
      }
      if (excludeIds != null && excludeIds.isNotEmpty) {
        q = q.not('id', 'in', '(${excludeIds.join(',')})');
      }

      final data = sortByLevel
          ? await q
                .order('level')
                .order('word')
                .range(offset, offset + limit - 1)
          : await q.order('word').range(offset, offset + limit - 1);

      final words = data.map(WordModel.fromJson).toList();
      return (words: words as List<Word>, hasMore: words.length == limit);
    } on Object catch (e, st) {
      debugPrint('[WordRemote] fetchPage error: $e\n$st');
      rethrow;
    }
  }

  Future<List<String>> fetchProgressIds({
    required String userId,
    String? status,
  }) async {
    try {
      var q = _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select('word_id')
          .eq('user_id', userId);
      if (status != null) q = q.eq('status', status);
      final data = await q;
      return data.map((r) => r['word_id'] as String).toList();
    } on Object catch (e, st) {
      debugPrint('[WordRemote] fetchProgressIds error: $e\n$st');
      rethrow;
    }
  }

  Future<Map<String, String>> fetchStatusMap({
    required String userId,
    required List<String> wordIds,
  }) async {
    if (wordIds.isEmpty) return {};
    try {
      final data = await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select('word_id, status')
          .eq('user_id', userId)
          .inFilter('word_id', wordIds);
      return {
        for (final r in data) r['word_id'] as String: r['status'] as String,
      };
    } on Object catch (e, st) {
      debugPrint('[WordRemote] fetchStatusMap error: $e\n$st');
      rethrow;
    }
  }
}
