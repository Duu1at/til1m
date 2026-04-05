import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/data/models/word_model.dart';
import 'package:til1m/domain/entities/word.dart';

class WordLocalDataSource {
  Future<void> cacheWords(List<Word> words) async {
    try {
      final box = await _wordsBox();
      final entries = {
        for (final w in words)
          w.id: (w is WordModel ? w : WordModel.fromJson(_wordToMap(w)))
              .toJson(),
      };
      await box.putAll(entries);
    } on Object catch (e, st) {
      debugPrint('[WordLocal] cacheWords error: $e\n$st');
    }
  }

  Future<
    ({
      List<Word> words,
      Map<String, String> statusMap,
      bool hasMore,
    })
  >
  fetchPage({
    required int offset,
    required int limit,
    String? searchQuery,
    WordLevel? level,
    String? statusFilter, // 'newWord' | 'learning' | 'known' | null (all)
    bool sortByLevel = false,
  }) async {
    try {
      final wordBox = await _wordsBox();
      final progressBox = await _progressBox();

      // Build status map from progress box
      final statusMap = <String, String>{};
      for (final entry in progressBox.toMap().entries) {
        final value = entry.value;
        if (value is! Map) continue;
        final wordId =
            value['word_id'] as String? ?? entry.key as String? ?? '';
        final status = value['status'] as String?;
        if (wordId.isNotEmpty && status != null) statusMap[wordId] = status;
      }

      // Parse all cached words
      var words = <Word>[];
      for (final value in wordBox.values) {
        if (value is! Map) continue;
        try {
          final json = Map<String, dynamic>.from(value);
          words.add(WordModel.fromJson(json));
        } on Object {
          continue;
        }
      }

      // Apply filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        words = words
            .where(
              (w) =>
                  w.word.toLowerCase().contains(q) ||
                  w.translations.any(
                    (t) => t.translation.toLowerCase().contains(q),
                  ),
            )
            .toList();
      }
      if (level != null) {
        words = words.where((w) => w.level == level).toList();
      }
      if (statusFilter != null && statusFilter != 'all') {
        if (statusFilter == 'newWord') {
          words = words.where((w) => !statusMap.containsKey(w.id)).toList();
        } else {
          words = words.where((w) => statusMap[w.id] == statusFilter).toList();
        }
      }

      // Sort
      if (sortByLevel) {
        words.sort((a, b) {
          final cmp = a.level.index.compareTo(b.level.index);
          return cmp != 0 ? cmp : a.word.compareTo(b.word);
        });
      } else {
        words.sort((a, b) => a.word.compareTo(b.word));
      }

      final hasMore = words.length > offset + limit;
      final page = words.skip(offset).take(limit).toList();

      // Build status map only for the current page
      final pageStatusMap = <String, String>{
        for (final w in page)
          if (statusMap.containsKey(w.id)) w.id: statusMap[w.id]!,
      };

      return (words: page, statusMap: pageStatusMap, hasMore: hasMore);
    } on Object catch (e, st) {
      debugPrint('[WordLocal] fetchPage error: $e\n$st');
      return (words: <Word>[], statusMap: <String, String>{}, hasMore: false);
    }
  }

  Future<Box<dynamic>> _wordsBox() async {
    return Hive.isBoxOpen(AppConstants.hiveBoxWords)
        ? Hive.box<dynamic>(AppConstants.hiveBoxWords)
        : Hive.openBox<dynamic>(AppConstants.hiveBoxWords);
  }

  Future<Box<dynamic>> _progressBox() async {
    return Hive.isBoxOpen(AppConstants.hiveBoxProgress)
        ? Hive.box<dynamic>(AppConstants.hiveBoxProgress)
        : Hive.openBox<dynamic>(AppConstants.hiveBoxProgress);
  }

  Map<String, dynamic> _wordToMap(Word w) => {
    'id': w.id,
    'word': w.word,
    'level': w.level.name,
    'part_of_speech': w.partOfSpeech.name,
    'created_at': w.createdAt.toIso8601String(),
    'transcription_text': w.transcriptionText,
    'audio_url': w.audioUrl,
    'image_url': w.imageUrl,
    'word_translations': w.translations
        .map(
          (t) => {
            'language': t.language,
            'translation': t.translation,
            'synonyms': t.synonyms,
          },
        )
        .toList(),
  };
}
