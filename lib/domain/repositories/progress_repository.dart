import 'package:til1m/domain/entities/user_progress.dart';
import 'package:til1m/domain/entities/word.dart';

abstract interface class ProgressRepository {
  Future<List<UserWordProgress>> getTodayReviewQueue(String userId);
  Future<List<UserWordProgress>> getNewWordsQueue(
    String userId,
    WordLevel level,
    int limit,
  );
  Future<UserWordProgress?> getWordProgress(String userId, String wordId);
  Future<void> saveProgress(UserWordProgress progress);
  Future<void> applySmResult({
    required String userId,
    required String wordId,
    required bool knew,
  });
  Future<int> getKnownWordsCount(String userId);
  Future<int> getTodayLearnedCount(String userId);
  Future<Map<String, int>> getProgressByLevel(String userId);
  Future<void> syncLocalToRemote(String userId);
}
