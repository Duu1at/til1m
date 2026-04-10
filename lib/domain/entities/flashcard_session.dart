import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/entities/word_progress.dart';

@immutable
final class FlashcardSessionItem extends Equatable {
  const FlashcardSessionItem({
    required this.word,
    required this.progress,
    this.isReview = false,
  });

  final Word word;

  final WordProgress progress;

  final bool isReview;

  @override
  List<Object?> get props => [word, progress, isReview];
}

@immutable
final class FlashcardSession extends Equatable {
  const FlashcardSession({
    required this.items,
    required this.sessionStartedAt,
    this.currentIndex = 0,
    this.failedWordIds = const [],
    this.answeredCount = 0,
    this.correctCount = 0,
  });

  final List<FlashcardSessionItem> items;

  final int currentIndex;

  final List<String> failedWordIds;

  final DateTime sessionStartedAt;

  final int answeredCount;

  final int correctCount;

  int get total => items.length;

  int get incorrectCount => answeredCount - correctCount;

  bool get isComplete => currentIndex >= items.length;

  FlashcardSessionItem? get current =>
      currentIndex < items.length ? items[currentIndex] : null;

  List<FlashcardSessionItem> get reviewItems =>
      items.where((i) => i.isReview).toList();

  List<FlashcardSessionItem> get newItems =>
      items.where((i) => !i.isReview).toList();

  FlashcardSession copyWith({
    List<FlashcardSessionItem>? items,
    int? currentIndex,
    List<String>? failedWordIds,
    int? answeredCount,
    int? correctCount,
  }) {
    return FlashcardSession(
      items: items ?? this.items,
      sessionStartedAt: sessionStartedAt,
      currentIndex: currentIndex ?? this.currentIndex,
      failedWordIds: failedWordIds ?? this.failedWordIds,
      answeredCount: answeredCount ?? this.answeredCount,
      correctCount: correctCount ?? this.correctCount,
    );
  }

  @override
  List<Object?> get props => [
    items,
    currentIndex,
    failedWordIds,
    answeredCount,
    correctCount,
  ];
}
