import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:til1m/domain/entities/user_progress.dart';
import 'package:til1m/domain/entities/word_progress.dart';

@immutable
final class Sm2Result extends Equatable {
  const Sm2Result({
    required this.updatedProgress,
    required this.interval,
    required this.returnToQueue,
  });

  final WordProgress updatedProgress;

  final int interval;

  final bool returnToQueue;

  @override
  List<Object?> get props => [updatedProgress, interval, returnToQueue];
}

final class CalculateSm2 {
  const CalculateSm2();

  static const int _quality = 4;

  static const double _easeCorrectDelta =
      0.1 - (5 - _quality) * (0.08 + (5 - _quality) * 0.02); // 0.0

  static const double _easeIncorrectPenalty = 0.2;

  static const double _minEaseFactor = 1.3;

  Sm2Result calculate({
    required WordProgress current,
    required bool isCorrect,
  }) {
    final now = DateTime.now();

    if (!isCorrect) {
      return Sm2Result(
        updatedProgress: current.copyWith(
          status: WordStatus.learning,
          repetitions: 0,
          easeFactor: (current.easeFactor - _easeIncorrectPenalty).clamp(
            _minEaseFactor,
            double.infinity,
          ),
          nextReviewAt: now,
          lastReviewedAt: now,
        ),
        interval: 0,
        returnToQueue: true,
      );
    }

    final newRepetitions = current.repetitions + 1;
    final int interval;

    if (current.repetitions == 0) {
      interval = 1;
    } else if (current.repetitions == 1) {
      interval = 6;
    } else {
      final prevInterval = _derivePreviousInterval(current);
      interval = (prevInterval * current.easeFactor).round();
    }

    final newEaseFactor = (current.easeFactor + _easeCorrectDelta).clamp(
      _minEaseFactor,
      double.infinity,
    );

    final newStatus = newRepetitions >= 3
        ? WordStatus.known
        : WordStatus.learning;

    return Sm2Result(
      updatedProgress: current.copyWith(
        status: newStatus,
        repetitions: newRepetitions,
        easeFactor: newEaseFactor,
        nextReviewAt: now.add(Duration(days: interval)),
        lastReviewedAt: now,
      ),
      interval: interval,
      returnToQueue: false,
    );
  }

  int _derivePreviousInterval(WordProgress progress) {
    final next = progress.nextReviewAt;
    final last = progress.lastReviewedAt;

    if (next != null && last != null) {
      final days = next.difference(last).inDays;
      if (days > 0) return days;
    }
    return 6;
  }
}
