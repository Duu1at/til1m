import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:til1m/domain/entities/user_progress.dart';

@immutable
final class WordProgress extends Equatable {
  const WordProgress({
    required this.wordId,
    this.status = WordStatus.newWord,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.nextReviewAt,
    this.lastReviewedAt,
  });

  final String wordId;
  final WordStatus status;
  final double easeFactor;
  final int repetitions;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;

  bool get isDueNow {
    if (nextReviewAt == null) return true;
    return nextReviewAt!.isBefore(DateTime.now());
  }

  WordProgress copyWith({
    WordStatus? status,
    double? easeFactor,
    int? repetitions,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
  }) {
    return WordProgress(
      wordId: wordId,
      status: status ?? this.status,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  @override
  List<Object?> get props => [wordId, status, easeFactor, repetitions];
}
