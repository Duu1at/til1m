import 'package:wordup/core/constants/app_constants.dart';
import 'package:wordup/domain/entities/user_progress.dart';
import 'package:wordup/domain/repositories/progress_repository.dart';

final class ApplySm2Result {
  const ApplySm2Result(this._repository);

  final ProgressRepository _repository;

  Future<UserWordProgress> call({
    required String userId,
    required String wordId,
    required bool knew,
  }) async {
    final existing = await _repository.getWordProgress(userId, wordId);

    final updated = _calculateNextReview(
      progress:
          existing ??
          UserWordProgress(
            id: '${userId}_$wordId',
            userId: userId,
            wordId: wordId,
          ),
      knew: knew,
    );

    await _repository.saveProgress(updated);
    return updated;
  }

  UserWordProgress _calculateNextReview({
    required UserWordProgress progress,
    required bool knew,
  }) {
    if (!knew) {
      return progress.copyWith(
        status: WordStatus.learning,
        repetitions: 0,
        easeFactor: (progress.easeFactor - 0.2).clamp(
          AppConstants.sm2MinEaseFactor,
          double.infinity,
        ),
        nextReviewAt: DateTime.now().add(const Duration(hours: 1)),
        lastReviewedAt: DateTime.now(),
      );
    }

    final newRepetitions = progress.repetitions + 1;
    final int interval;

    if (newRepetitions == 1) {
      interval = AppConstants.sm2FirstInterval;
    } else if (newRepetitions == 2) {
      interval = AppConstants.sm2SecondInterval;
    } else {
      interval = (progress.easeFactor * (newRepetitions - 1)).round();
    }

    final newEaseFactor = (progress.easeFactor + 0.1).clamp(
      AppConstants.sm2MinEaseFactor,
      double.infinity,
    );

    return progress.copyWith(
      status: interval >= 21 ? WordStatus.known : WordStatus.learning,
      repetitions: newRepetitions,
      easeFactor: newEaseFactor,
      nextReviewAt: DateTime.now().add(Duration(days: interval)),
      lastReviewedAt: DateTime.now(),
    );
  }
}
