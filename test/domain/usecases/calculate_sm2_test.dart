import 'package:flutter_test/flutter_test.dart';
import 'package:til1m/domain/entities/user_progress.dart';
import 'package:til1m/domain/entities/word_progress.dart';
import 'package:til1m/domain/usecases/calculate_sm2.dart';

void main() {
  const sut = CalculateSm2();

  // ─── Helpers ────────────────────────────────────────────────────────────────

  WordProgress progress({
    int repetitions = 0,
    double easeFactor = 2.5,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    WordStatus status = WordStatus.newWord,
  }) {
    return WordProgress(
      wordId: 'word-1',
      repetitions: repetitions,
      easeFactor: easeFactor,
      lastReviewedAt: lastReviewedAt,
      nextReviewAt: nextReviewAt,
      status: status,
    );
  }

  // ─── Correct answers ─────────────────────────────────────────────────────────

  group('correct answer', () {
    test('new word (repetitions=0) → interval 1 day, repetitions 1, status learning', () {
      final result = sut.calculate(
        current: progress(),
        isCorrect: true,
      );

      expect(result.interval, 1);
      expect(result.returnToQueue, isFalse);
      expect(result.updatedProgress.repetitions, 1);
      expect(result.updatedProgress.status, WordStatus.learning);
      _expectNextReviewInDays(result.updatedProgress.nextReviewAt, 1);
    });

    test('word with 1 repetition → interval 6 days, repetitions 2, status learning', () {
      final result = sut.calculate(
        current: progress(repetitions: 1),
        isCorrect: true,
      );

      expect(result.interval, 6);
      expect(result.returnToQueue, isFalse);
      expect(result.updatedProgress.repetitions, 2);
      expect(result.updatedProgress.status, WordStatus.learning);
      _expectNextReviewInDays(result.updatedProgress.nextReviewAt, 6);
    });

    test('word with 2 repetitions → interval = prevInterval × easeFactor, repetitions 3, status known', () {
      final now = DateTime.now();

      // Previous review scheduled this word 6 days out.
      final result = sut.calculate(
        current: progress(
          repetitions: 2,
          lastReviewedAt: now.subtract(const Duration(days: 6)),
          nextReviewAt: now,
        ),
        isCorrect: true,
      );

      const expectedInterval = 15; // (6 * 2.5).round()

      expect(result.interval, expectedInterval);
      expect(result.returnToQueue, isFalse);
      expect(result.updatedProgress.repetitions, 3);
      expect(result.updatedProgress.status, WordStatus.known);
      _expectNextReviewInDays(result.updatedProgress.nextReviewAt, expectedInterval);
    });

    test('word with 2 repetitions and custom easeFactor → interval scales correctly', () {
      final now = DateTime.now();

      final result = sut.calculate(
        current: progress(
          repetitions: 2,
          easeFactor: 2,
          lastReviewedAt: now.subtract(const Duration(days: 6)),
          nextReviewAt: now,
        ),
        isCorrect: true,
      );

      const expectedInterval = 12; // (6 * 2.0).round()
      expect(result.interval, expectedInterval);
      _expectNextReviewInDays(result.updatedProgress.nextReviewAt, expectedInterval);
    });

    test('correct answer with quality=4 does not change easeFactor', () {
      const ef = 2.1; // non-default to make the assertion meaningful
      final result = sut.calculate(
        current: progress(easeFactor: ef),
        isCorrect: true,
      );

      // delta = 0.1 - (5-4)*(0.08+(5-4)*0.02) = 0.0
      expect(result.updatedProgress.easeFactor, ef);
    });

    test('lastReviewedAt is set to approximately now after correct answer', () {
      final before = DateTime.now();
      final result = sut.calculate(
        current: progress(),
        isCorrect: true,
      );
      final after = DateTime.now();

      expect(
        result.updatedProgress.lastReviewedAt!
            .isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        result.updatedProgress.lastReviewedAt!
            .isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });

  // ─── Incorrect answers ───────────────────────────────────────────────────────

  group('incorrect answer', () {
    test('any word + incorrect → repetitions reset to 0, returnToQueue true', () {
      final result = sut.calculate(
        current: progress(repetitions: 5, easeFactor: 2),
        isCorrect: false,
      );

      expect(result.interval, 0);
      expect(result.returnToQueue, isTrue);
      expect(result.updatedProgress.repetitions, 0);
      expect(result.updatedProgress.status, WordStatus.learning);
    });

    test('incorrect answer → nextReviewAt set to approximately now (return to queue)', () {
      final before = DateTime.now();
      final result = sut.calculate(
        current: progress(),
        isCorrect: false,
      );
      final after = DateTime.now();

      expect(
        result.updatedProgress.nextReviewAt!
            .isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        result.updatedProgress.nextReviewAt!
            .isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('incorrect answer reduces easeFactor by 0.2', () {
      final result = sut.calculate(
        current: progress(),
        isCorrect: false,
      );

      expect(result.updatedProgress.easeFactor, closeTo(2.3, 0.001));
    });
  });

  // ─── easeFactor floor ─────────────────────────────────────────────────────────

  group('easeFactor minimum', () {
    test('easeFactor never drops below 1.3 after incorrect answer', () {
      final result = sut.calculate(
        current: progress(easeFactor: 1.3),
        isCorrect: false,
      );

      expect(result.updatedProgress.easeFactor, 1.3);
    });

    test('easeFactor stays at 1.3 after multiple incorrect answers', () {
      var current = progress(easeFactor: 1.4);

      for (var i = 0; i < 5; i++) {
        final result = sut.calculate(current: current, isCorrect: false);
        current = result.updatedProgress;
        expect(current.easeFactor, greaterThanOrEqualTo(1.3));
      }
    });

    test('easeFactor is not raised above its current value on correct answer with quality=4', () {
      const ef = 1.5;
      final result = sut.calculate(
        current: progress(easeFactor: ef),
        isCorrect: true,
      );

      // delta = 0.0 for quality=4, so ef stays the same
      expect(result.updatedProgress.easeFactor, ef);
    });
  });

  // ─── Status transitions ───────────────────────────────────────────────────────

  group('status transitions', () {
    test('status becomes known at repetitions=3', () {
      final now = DateTime.now();
      final result = sut.calculate(
        current: progress(
          repetitions: 2,
          lastReviewedAt: now.subtract(const Duration(days: 6)),
          nextReviewAt: now,
        ),
        isCorrect: true,
      );

      expect(result.updatedProgress.status, WordStatus.known);
    });

    test('status remains learning at repetitions=1', () {
      final result = sut.calculate(
        current: progress(),
        isCorrect: true,
      );

      expect(result.updatedProgress.status, WordStatus.learning);
    });

    test('status remains learning at repetitions=2', () {
      final result = sut.calculate(
        current: progress(repetitions: 1),
        isCorrect: true,
      );

      expect(result.updatedProgress.status, WordStatus.learning);
    });

    test('incorrect answer always sets status to learning, even if was known', () {
      final result = sut.calculate(
        current: progress(repetitions: 10, status: WordStatus.known),
        isCorrect: false,
      );

      expect(result.updatedProgress.status, WordStatus.learning);
    });
  });

  // ─── Interval derivation ──────────────────────────────────────────────────────

  group('interval derivation from timestamps', () {
    test('uses nextReviewAt - lastReviewedAt as previous interval', () {
      final now = DateTime.now();
      final result = sut.calculate(
        current: progress(
          repetitions: 2,
          lastReviewedAt: now.subtract(const Duration(days: 10)),
          nextReviewAt: now, // diff = 10 days
        ),
        isCorrect: true,
      );

      const expectedInterval = 25; // (10 * 2.5).round()
      expect(result.interval, expectedInterval);
    });

    test('falls back to 6-day interval when timestamps are missing', () {
      final result = sut.calculate(
        current: progress(repetitions: 2),
        isCorrect: true,
      );

      const expectedInterval = 15; // (6 * 2.5).round()
      expect(result.interval, expectedInterval);
    });
  });
}

// ─── Matchers ────────────────────────────────────────────────────────────────

/// Checks that [nextReviewAt] is approximately [days] days from now.
void _expectNextReviewInDays(DateTime? nextReviewAt, int days) {
  expect(nextReviewAt, isNotNull);
  final expected = DateTime.now().add(Duration(days: days));
  final diff = nextReviewAt!.difference(expected).abs();
  expect(
    diff.inSeconds,
    lessThan(5),
    reason: 'Expected nextReviewAt ≈ now + $days days, '
        'but got difference of ${diff.inSeconds}s',
  );
}
