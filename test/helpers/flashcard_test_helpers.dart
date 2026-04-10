import 'package:til1m/domain/entities/flashcard_session.dart';
import 'package:til1m/domain/entities/user_progress.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/entities/word_progress.dart';

/// Builds a minimal [Word] for tests.
Word testWord({
  String id = 'word-1',
  String word = 'apple',
  WordLevel level = WordLevel.a1,
  String? transcription = 'ˈæp.əl',
  List<Translation>? translations,
  List<WordExample>? examples,
}) => Word(
  id: id,
  word: word,
  level: level,
  partOfSpeech: PartOfSpeech.noun,
  createdAt: DateTime(2024),
  transcriptionText: transcription,
  translations:
      translations ??
      const [
        Translation(
          language: TranslationLanguage.ru,
          translation: 'яблоко',
          synonyms: ['фрукт'],
        ),
      ],
  examples: examples ?? const [],
);

/// Builds a [WordProgress] with default SM-2 values.
WordProgress testProgress({
  String wordId = 'word-1',
  int repetitions = 0,
  double easeFactor = 2.5,
  WordStatus status = WordStatus.newWord,
  DateTime? nextReviewAt,
  DateTime? lastReviewedAt,
}) => WordProgress(
  wordId: wordId,
  repetitions: repetitions,
  easeFactor: easeFactor,
  status: status,
  nextReviewAt: nextReviewAt,
  lastReviewedAt: lastReviewedAt,
);

/// Builds a [UserWordProgress] bound to a specific user.
UserWordProgress testUserWordProgress({
  String userId = 'user-1',
  String wordId = 'word-1',
  int repetitions = 0,
  double easeFactor = 2.5,
  WordStatus status = WordStatus.newWord,
  DateTime? nextReviewAt,
  DateTime? lastReviewedAt,
}) => UserWordProgress(
  id: '${userId}_$wordId',
  userId: userId,
  wordId: wordId,
  repetitions: repetitions,
  easeFactor: easeFactor,
  status: status,
  nextReviewAt: nextReviewAt,
  lastReviewedAt: lastReviewedAt,
);

/// Builds a [FlashcardSessionItem] for use in session tests.
FlashcardSessionItem testItem({
  String wordId = 'word-1',
  String wordText = 'apple',
  bool isReview = false,
}) => FlashcardSessionItem(
  word: testWord(id: wordId, word: wordText),
  progress: testProgress(wordId: wordId),
  isReview: isReview,
);

/// Builds a [FlashcardSession] with [items], defaulting to one item.
FlashcardSession testSession({
  List<FlashcardSessionItem>? items,
  int currentIndex = 0,
  int answeredCount = 0,
  int correctCount = 0,
}) {
  final sessionItems = items ?? [testItem()];
  return FlashcardSession(
    items: sessionItems,
    sessionStartedAt: DateTime(2024),
    currentIndex: currentIndex,
    answeredCount: answeredCount,
    correctCount: correctCount,
  );
}
