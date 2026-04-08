part of 'word_detail_cubit.dart';

sealed class WordDetailState extends Equatable {
  const WordDetailState();
}

final class WordDetailInitial extends WordDetailState {
  const WordDetailInitial();
  @override
  List<Object?> get props => [];
}

final class WordDetailLoading extends WordDetailState {
  const WordDetailLoading();
  @override
  List<Object?> get props => [];
}

final class WordDetailLoaded extends WordDetailState {
  const WordDetailLoaded({
    required this.word,
    required this.isFavorite,
    this.progress,
    this.isProcessingProgress = false,
    this.isPlaying = false,
    this.lastAnswerKnew,
  });

  final Word word;
  final bool isFavorite;
  final Map<String, dynamic>? progress;
  final bool isProcessingProgress;
  final bool isPlaying;
  final bool? lastAnswerKnew;

  WordDetailLoaded copyWith({
    bool? isFavorite,
    Map<String, dynamic>? progress,
    bool? isProcessingProgress,
    bool? isPlaying,
    bool? lastAnswerKnew,
  }) => WordDetailLoaded(
    word: word,
    isFavorite: isFavorite ?? this.isFavorite,
    progress: progress ?? this.progress,
    isProcessingProgress: isProcessingProgress ?? this.isProcessingProgress,
    isPlaying: isPlaying ?? this.isPlaying,
    lastAnswerKnew: lastAnswerKnew ?? this.lastAnswerKnew,
  );

  @override
  List<Object?> get props => [
    word,
    isFavorite,
    progress,
    isProcessingProgress,
    isPlaying,
    lastAnswerKnew,
  ];
}

final class WordDetailError extends WordDetailState {
  const WordDetailError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
