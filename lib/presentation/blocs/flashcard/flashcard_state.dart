part of 'flashcard_bloc.dart';

enum FlashcardSource {
  review,
  newWords,
  mixed,
}

@immutable
final class UndoAction extends Equatable {
  const UndoAction({
    required this.item,
    required this.wasCorrect,
    required this.previousProgress,
  });

  final FlashcardSessionItem item;

  final bool wasCorrect;

  final WordProgress previousProgress;

  @override
  List<Object?> get props => [item, wasCorrect, previousProgress];
}

sealed class FlashcardState {
  const FlashcardState();
}

final class FlashcardInitial extends FlashcardState {
  const FlashcardInitial();
}

final class FlashcardLoading extends FlashcardState {
  const FlashcardLoading();
}

final class FlashcardActive extends FlashcardState with EquatableMixin {
  const FlashcardActive({
    required this.currentWord,
    required this.currentProgress,
    required this.isCurrentReview,
    required this.isFlipped,
    required this.currentIndex,
    required this.totalWords,
    required this.answeredCount,
    required this.correctCount,
    required this.reviewCount,
    required this.newCount,
    required this.canUndo,
    required this.isAudioPlaying,
    this.isOffline = false,
    this.syncMessage,
  });

  final Word currentWord;

  final WordProgress currentProgress;

  final bool isCurrentReview;

  final bool isFlipped;

  final int currentIndex;

  final int totalWords;

  final int answeredCount;

  final int correctCount;

  final int reviewCount;

  final int newCount;

  final bool canUndo;

  final bool isAudioPlaying;

  final bool isOffline;

  final String? syncMessage;

  int get incorrectCount => answeredCount - correctCount;

  FlashcardActive copyWith({
    Word? currentWord,
    WordProgress? currentProgress,
    bool? isCurrentReview,
    bool? isFlipped,
    int? currentIndex,
    int? totalWords,
    int? answeredCount,
    int? correctCount,
    int? reviewCount,
    int? newCount,
    bool? canUndo,
    bool? isAudioPlaying,
    bool? isOffline,
    Object? syncMessage = _keep,
  }) {
    return FlashcardActive(
      currentWord: currentWord ?? this.currentWord,
      currentProgress: currentProgress ?? this.currentProgress,
      isCurrentReview: isCurrentReview ?? this.isCurrentReview,
      isFlipped: isFlipped ?? this.isFlipped,
      currentIndex: currentIndex ?? this.currentIndex,
      totalWords: totalWords ?? this.totalWords,
      answeredCount: answeredCount ?? this.answeredCount,
      correctCount: correctCount ?? this.correctCount,
      reviewCount: reviewCount ?? this.reviewCount,
      newCount: newCount ?? this.newCount,
      canUndo: canUndo ?? this.canUndo,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
      isOffline: isOffline ?? this.isOffline,
      syncMessage: identical(syncMessage, _keep)
          ? this.syncMessage
          : syncMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    currentWord,
    currentProgress,
    isCurrentReview,
    isFlipped,
    currentIndex,
    totalWords,
    answeredCount,
    correctCount,
    reviewCount,
    newCount,
    canUndo,
    isAudioPlaying,
    isOffline,
    syncMessage,
  ];
}

const Object _keep = Object();

final class FlashcardSessionComplete extends FlashcardState
    with EquatableMixin {
  const FlashcardSessionComplete({
    required this.totalAnswered,
    required this.correctCount,
    required this.incorrectCount,
    required this.newWordsLearned,
    required this.wordsReviewed,
    required this.sessionDuration,
    required this.dailyGoalReached,
    this.currentStreak = 0,
  });

  final int totalAnswered;
  final int correctCount;
  final int incorrectCount;
  final int newWordsLearned;
  final int wordsReviewed;
  final Duration sessionDuration;
  final bool dailyGoalReached;

  final int currentStreak;

  @override
  List<Object?> get props => [
    totalAnswered,
    correctCount,
    incorrectCount,
    newWordsLearned,
    wordsReviewed,
    sessionDuration,
    dailyGoalReached,
    currentStreak,
  ];
}

final class FlashcardEmpty extends FlashcardState {
  const FlashcardEmpty({required this.source});

  final FlashcardSource source;
}

final class FlashcardError extends FlashcardState {
  const FlashcardError({required this.message});

  final String message;
}
