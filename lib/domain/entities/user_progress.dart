import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum WordStatus { newWord, learning, known }

@immutable
final class UserWordProgress extends Equatable {
  const UserWordProgress({
    required this.id,
    required this.userId,
    required this.wordId,
    this.status = WordStatus.newWord,
    this.nextReviewAt,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.lastReviewedAt,
  });

  final String id;
  final String userId;
  final String wordId;
  final WordStatus status;
  final DateTime? nextReviewAt;
  final double easeFactor;
  final int repetitions;
  final DateTime? lastReviewedAt;

  bool get isDueToday {
    if (nextReviewAt == null) return true;
    return nextReviewAt!.isBefore(DateTime.now());
  }

  UserWordProgress copyWith({
    WordStatus? status,
    DateTime? nextReviewAt,
    double? easeFactor,
    int? repetitions,
    DateTime? lastReviewedAt,
  }) {
    return UserWordProgress(
      id: id,
      userId: userId,
      wordId: wordId,
      status: status ?? this.status,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, wordId, status, repetitions];
}
