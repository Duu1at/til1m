part of 'flashcards_bloc.dart';

// ─── FlashcardItem ────────────────────────────────────────────────────────────

final class FlashcardItem extends Equatable {
  const FlashcardItem({
    required this.word,
    required this.easeFactor,
    required this.repetitions,
    required this.isReview,
  });

  final Word word;
  final double easeFactor;
  final int repetitions;

  /// true = was already seen (due for review), false = brand-new word
  final bool isReview;

  @override
  List<Object?> get props => [word, easeFactor, repetitions, isReview];
}

// ─── Session stats ────────────────────────────────────────────────────────────

final class FlashcardsSessionStats extends Equatable {
  const FlashcardsSessionStats({this.knew = 0, this.didntKnow = 0});

  final int knew;
  final int didntKnow;

  int get total => knew + didntKnow;
  int get accuracyPercent =>
      total == 0 ? 0 : ((knew / total) * 100).round();

  FlashcardsSessionStats withKnew() =>
      FlashcardsSessionStats(knew: knew + 1, didntKnow: didntKnow);

  FlashcardsSessionStats withDidntKnow() =>
      FlashcardsSessionStats(knew: knew, didntKnow: didntKnow + 1);

  @override
  List<Object?> get props => [knew, didntKnow];
}

// ─── States ───────────────────────────────────────────────────────────────────

sealed class FlashcardsState extends Equatable {
  const FlashcardsState();
}

final class FlashcardsInitial extends FlashcardsState {
  const FlashcardsInitial();

  @override
  List<Object?> get props => [];
}

final class FlashcardsLoading extends FlashcardsState {
  const FlashcardsLoading();

  @override
  List<Object?> get props => [];
}

final class FlashcardsActive extends FlashcardsState {
  const FlashcardsActive({
    required this.queue,
    required this.currentIndex,
    required this.isFlipped,
    required this.stats,
    required this.uiLanguage,
    required this.isGuest,
    required this.userId,
  });

  final List<FlashcardItem> queue;
  final int currentIndex;
  final bool isFlipped;
  final FlashcardsSessionStats stats;
  final String uiLanguage;
  final bool isGuest;
  final String userId;

  FlashcardItem get current => queue[currentIndex];
  bool get isLast => currentIndex == queue.length - 1;
  int get totalCards => queue.length;

  FlashcardsActive copyWith({
    List<FlashcardItem>? queue,
    int? currentIndex,
    bool? isFlipped,
    FlashcardsSessionStats? stats,
  }) {
    return FlashcardsActive(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      stats: stats ?? this.stats,
      uiLanguage: uiLanguage,
      isGuest: isGuest,
      userId: userId,
    );
  }

  @override
  List<Object?> get props => [
    queue,
    currentIndex,
    isFlipped,
    stats,
    uiLanguage,
    isGuest,
    userId,
  ];
}

final class FlashcardsSessionComplete extends FlashcardsState {
  const FlashcardsSessionComplete({required this.stats});

  final FlashcardsSessionStats stats;

  @override
  List<Object?> get props => [stats];
}

final class FlashcardsEmpty extends FlashcardsState {
  const FlashcardsEmpty();

  @override
  List<Object?> get props => [];
}

final class FlashcardsError extends FlashcardsState {
  const FlashcardsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
