import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/data/models/flashcard_session_model.dart';
import 'package:til1m/data/models/word_model.dart';
import 'package:til1m/data/models/word_progress_model.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/entities/word_progress.dart';

class FlashcardLocalDataSource {
  // ─── Box helpers ─────────────────────────────────────────────────────────────

  Future<Box<dynamic>> _wordsBox() async =>
      Hive.isBoxOpen(AppConstants.hiveBoxWords)
          ? Hive.box(AppConstants.hiveBoxWords)
          : Hive.openBox(AppConstants.hiveBoxWords);

  Future<Box<dynamic>> _progressBox() async =>
      Hive.isBoxOpen(AppConstants.hiveBoxProgress)
          ? Hive.box(AppConstants.hiveBoxProgress)
          : Hive.openBox(AppConstants.hiveBoxProgress);

  Future<Box<dynamic>> _sessionBox() async =>
      Hive.isBoxOpen(AppConstants.hiveBoxSession)
          ? Hive.box(AppConstants.hiveBoxSession)
          : Hive.openBox(AppConstants.hiveBoxSession);

  // ─── Words ────────────────────────────────────────────────────────────────────

  /// Writes [words] into the words cache box (keyed by word ID).
  Future<void> cacheWords(List<Word> words) async {
    try {
      final box = await _wordsBox();
      final entries = <String, dynamic>{};
      for (final w in words) {
        final model = w is WordModel ? w : WordModel.fromJson(_wordToMap(w));
        entries[w.id] = model.toJson();
      }
      await box.putAll(entries);
    } on Object catch (e, st) {
      debugPrint('[FlashcardLocal] cacheWords error: $e\n$st');
    }
  }

  /// Returns cached words, optionally filtered by [level] or [excludeIds].
  Future<List<Word>> getCachedWords({
    WordLevel? level,
    List<String>? excludeIds,
    int? limit,
  }) async {
    try {
      final box = await _wordsBox();
      var words = <Word>[];

      for (final value in box.values) {
        if (value is! Map) continue;
        try {
          words.add(WordModel.fromJson(Map<String, dynamic>.from(value)));
        } on Object {
          continue;
        }
      }

      if (level != null) {
        words = words.where((w) => w.level == level).toList();
      }
      if (excludeIds != null && excludeIds.isNotEmpty) {
        final excludeSet = excludeIds.toSet();
        words = words.where((w) => !excludeSet.contains(w.id)).toList();
      }

      words.sort((a, b) => a.word.compareTo(b.word));
      return limit != null ? words.take(limit).toList() : words;
    } on Object catch (e, st) {
      debugPrint('[FlashcardLocal] getCachedWords error: $e\n$st');
      return [];
    }
  }

  /// Returns cached words as a `{id: Word}` map — used for session restoration.
  Future<Map<String, Word>> getCachedWordMap(List<String> wordIds) async {
    try {
      final box = await _wordsBox();
      final result = <String, Word>{};

      for (final id in wordIds) {
        final value = box.get(id);
        if (value is! Map) continue;
        try {
          result[id] =
              WordModel.fromJson(Map<String, dynamic>.from(value));
        } on Object {
          continue;
        }
      }
      return result;
    } on Object catch (e, st) {
      debugPrint('[FlashcardLocal] getCachedWordMap error: $e\n$st');
      return {};
    }
  }

  // ─── Progress ─────────────────────────────────────────────────────────────────

  /// Returns progress entries whose `next_review_at` is ≤ now.
  Future<List<WordProgress>> getDueProgress({int? limit}) async {
    try {
      final box = await _progressBox();
      final now = DateTime.now();
      final result = <WordProgress>[];

      for (final entry in box.toMap().entries) {
        final value = entry.value;
        if (value is! Map) continue;

        final nextStr = value['next_review_at'] as String?;
        final isDue =
            nextStr == null || (DateTime.tryParse(nextStr)?.isBefore(now) ?? true);

        if (!isDue) continue;

        try {
          final wordId =
              value['word_id'] as String? ?? entry.key as String? ?? '';
          if (wordId.isEmpty) continue;

          result.add(
            WordProgressModel.fromHive({
              ...Map<String, dynamic>.from(value),
              'word_id': wordId,
            }).toEntity(),
          );
        } on Object {
          continue;
        }
      }

      return limit != null ? result.take(limit).toList() : result;
    } on Object catch (e, st) {
      debugPrint('[FlashcardLocal] getDueProgress error: $e\n$st');
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
            value['word_id'] as String? ??
            entry.key as String? ??
            '';
        if (wordId.isNotEmpty) ids.add(wordId);
      }
      return ids;
    } on Object catch (e, st) {
      debugPrint('[FlashcardLocal] getAllProgressWordIds error: $e\n$st');
      return [];
    }
  }

  Future<WordProgress?> getProgressForWord(String wordId) async {
    try {
      final box = await _progressBox();
      final value = box.get(wordId);
      if (value is! Map) return null;
      return WordProgressModel.fromHive({
        ...Map<String, dynamic>.from(value),
        'word_id': wordId,
      }).toEntity();
    } on Object catch (e, st) {
      debugPrint('[FlashcardLocal] getProgressForWord error: $e\n$st');
      return null;
    }
  }

  Future<void> saveProgress(WordProgress progress) async {
    try {
      final box = await _progressBox();
      await box.put(
        progress.wordId,
        WordProgressModel.fromEntity(progress).toHive(),
      );
    } on Object catch (e, st) {
      debugPrint('[FlashcardLocal] saveProgress error: $e\n$st');
    }
  }

  Future<List<WordProgress>> getAllProgress() async {
    try {
      final box = await _progressBox();
      final result = <WordProgress>[];

      for (final entry in box.toMap().entries) {
        final value = entry.value;
        if (value is! Map) continue;
        try {
          final wordId =
              value['word_id'] as String? ??
              entry.key as String? ??
              '';
          if (wordId.isEmpty) continue;

          result.add(
            WordProgressModel.fromHive({
              ...Map<String, dynamic>.from(value),
              'word_id': wordId,
            }).toEntity(),
          );
        } on Object {
          continue;
        }
      }
      return result;
    } on Object catch (e, st) {
      debugPrint('[FlashcardLocal] getAllProgress error: $e\n$st');
      return [];
    }
  }

  Future<Map<String, int>> fetchProgressStats() async {
    try {
      final box = await _progressBox();
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      var known = 0;
      var learning = 0;
      var todayReviewed = 0;
      var due = 0;

      for (final value in box.values) {
        if (value is! Map) continue;

        switch (value['status'] as String?) {
          case 'known':
            known++;
          case 'learning':
            learning++;
        }

        final lastStr = value['last_reviewed_at'] as String?;
        if (lastStr != null) {
          final dt = DateTime.tryParse(lastStr);
          if (dt != null && dt.isAfter(todayStart)) todayReviewed++;
        }

        final nextStr = value['next_review_at'] as String?;
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
    } on Object catch (e, st) {
      debugPrint('[FlashcardLocal] fetchProgressStats error: $e\n$st');
      return {'known': 0, 'learning': 0, 'today_reviewed': 0, 'due': 0};
    }
  }

  /// Counts progress entries grouped by word level (requires word cache lookup).
  Future<Map<String, int>> fetchProgressByLevel() async {
    try {
      final progressIds = await getAllProgressWordIds();
      if (progressIds.isEmpty) return {};

      final wordBox = await _wordsBox();
      final counts = <String, int>{};

      for (final wordId in progressIds) {
        final value = wordBox.get(wordId);
        if (value is! Map) continue;
        final level = value['level'] as String? ?? 'a1';
        counts[level.toLowerCase()] = (counts[level.toLowerCase()] ?? 0) + 1;
      }
      return counts;
    } on Object catch (e, st) {
      debugPrint('[FlashcardLocal] fetchProgressByLevel error: $e\n$st');
      return {};
    }
  }

  // ─── Session state ────────────────────────────────────────────────────────────

  static const _sessionKey = 'current_session';

  /// Persists [session] so it can be restored after the app is closed.
  Future<void> saveSessionState(FlashcardSessionModel session) async {
    try {
      final box = await _sessionBox();
      await box.put(_sessionKey, session.toHive());
    } on Object catch (e, st) {
      debugPrint('[FlashcardLocal] saveSessionState error: $e\n$st');
    }
  }

  /// Returns the last saved session, or `null` if none exists.
  Future<FlashcardSessionModel?> getSessionState() async {
    try {
      final box = await _sessionBox();
      final value = box.get(_sessionKey);
      if (value is! Map) return null;
      return FlashcardSessionModel.fromHive(
        Map<String, dynamic>.from(value),
      );
    } on Object catch (e, st) {
      debugPrint('[FlashcardLocal] getSessionState error: $e\n$st');
      return null;
    }
  }

  /// Removes the persisted session (call on normal completion or restart).
  Future<void> clearSessionState() async {
    try {
      final box = await _sessionBox();
      await box.delete(_sessionKey);
    } on Object catch (e, st) {
      debugPrint('[FlashcardLocal] clearSessionState error: $e\n$st');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

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
                'language': t.language.name,
                'translation': t.translation,
                'synonyms': t.synonyms,
              },
            )
            .toList(),
      };
}
