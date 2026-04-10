import 'package:til1m/data/models/word_progress_model.dart';
import 'package:til1m/domain/entities/flashcard_session.dart';
import 'package:til1m/domain/entities/word.dart';

/// Serialisable snapshot of a [FlashcardSession] for Hive persistence.
///
/// Stores word IDs + SM-2 progress data so the session can be resumed
/// after the app is closed. Full [Word] objects are looked up from the
/// words cache when restoring via [toSession].
final class FlashcardSessionModel {
  const FlashcardSessionModel({
    required this.wordIds,
    required this.progressSnapshot,
    required this.isReviewMap,
    required this.currentIndex,
    required this.failedWordIds,
    required this.sessionStartedAt,
    this.answeredCount = 0,
    this.correctCount = 0,
  });

  // ─── Constructors ─────────────────────────────────────────────────────────────

  factory FlashcardSessionModel.fromSession(FlashcardSession session) {
    final wordIds = session.items.map((i) => i.word.id).toList();
    final progressSnapshot = <String, Map<String, dynamic>>{};
    final isReviewMap = <String, bool>{};

    for (final item in session.items) {
      progressSnapshot[item.word.id] =
          WordProgressModel.fromEntity(item.progress).toHive();
      isReviewMap[item.word.id] = item.isReview;
    }

    return FlashcardSessionModel(
      wordIds: wordIds,
      progressSnapshot: progressSnapshot,
      isReviewMap: isReviewMap,
      currentIndex: session.currentIndex,
      failedWordIds: List.unmodifiable(session.failedWordIds),
      sessionStartedAt: session.sessionStartedAt.toIso8601String(),
      answeredCount: session.answeredCount,
      correctCount: session.correctCount,
    );
  }

  factory FlashcardSessionModel.fromHive(Map<String, dynamic> map) {
    final wordIds = (map['word_ids'] as List?)?.cast<String>() ?? [];

    final rawProgress = map['progress_snapshot'] as Map? ?? {};
    final progressSnapshot = <String, Map<String, dynamic>>{};
    for (final entry in rawProgress.entries) {
      if (entry.value is Map) {
        progressSnapshot[entry.key as String] =
            Map<String, dynamic>.from(entry.value as Map);
      }
    }

    final rawReview = map['is_review_map'] as Map? ?? {};
    final isReviewMap = <String, bool>{};
    for (final entry in rawReview.entries) {
      isReviewMap[entry.key as String] = (entry.value as bool?) ?? false;
    }

    return FlashcardSessionModel(
      wordIds: wordIds,
      progressSnapshot: progressSnapshot,
      isReviewMap: isReviewMap,
      currentIndex: map['current_index'] as int? ?? 0,
      failedWordIds:
          (map['failed_word_ids'] as List?)?.cast<String>() ?? const [],
      sessionStartedAt: map['session_started_at'] as String? ??
          DateTime.now().toIso8601String(),
      answeredCount: map['answered_count'] as int? ?? 0,
      correctCount: map['correct_count'] as int? ?? 0,
    );
  }

  // ─── Fields ───────────────────────────────────────────────────────────────────

  /// Ordered word IDs — defines the session queue.
  final List<String> wordIds;

  /// SM-2 state for each word at snapshot time (Hive-serialised form).
  final Map<String, Map<String, dynamic>> progressSnapshot;

  /// Whether each word is a review (true) or new (false).
  final Map<String, bool> isReviewMap;

  final int currentIndex;
  final List<String> failedWordIds;

  /// ISO-8601 string.
  final String sessionStartedAt;

  final int answeredCount;
  final int correctCount;

  // ─── Serialisation ────────────────────────────────────────────────────────────

  Map<String, dynamic> toHive() => {
        'word_ids': wordIds,
        'progress_snapshot': progressSnapshot,
        'is_review_map': isReviewMap,
        'current_index': currentIndex,
        'failed_word_ids': failedWordIds,
        'session_started_at': sessionStartedAt,
        'answered_count': answeredCount,
        'correct_count': correctCount,
      };

  // ─── Domain conversion ────────────────────────────────────────────────────────

  /// Reconstructs a [FlashcardSession] using [wordCache].
  ///
  /// Words missing from the cache are silently skipped.
  /// Returns `null` if no items could be resolved.
  FlashcardSession? toSession(Map<String, Word> wordCache) {
    final items = <FlashcardSessionItem>[];

    for (final wordId in wordIds) {
      final word = wordCache[wordId];
      if (word == null) continue;

      final rawProgress =
          progressSnapshot[wordId] ?? <String, dynamic>{'word_id': wordId};
      final progress = WordProgressModel.fromHive({
        ...rawProgress,
        'word_id': wordId,
      }).toEntity();

      items.add(FlashcardSessionItem(
        word: word,
        progress: progress,
        isReview: isReviewMap[wordId] ?? false,
      ));
    }

    if (items.isEmpty) return null;

    return FlashcardSession(
      items: items,
      currentIndex: currentIndex,
      failedWordIds: failedWordIds,
      sessionStartedAt:
          DateTime.tryParse(sessionStartedAt) ?? DateTime.now(),
      answeredCount: answeredCount,
      correctCount: correctCount,
    );
  }
}
