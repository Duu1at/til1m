import '../entities/user_progress.dart';
import '../entities/word.dart';

abstract class ProgressRepository {
  Future<List<UserWordProgress>> getTodayReviewQueue(String userId);
  Future<List<UserWordProgress>> getNewWordsQueue(String userId, WordLevel level, int limit);
  Future<UserWordProgress?> getWordProgress(String userId, String wordId);
  Future<void> saveProgress(UserWordProgress progress);
  Future<void> applySmResult(String userId, String wordId, bool knew);
  Future<int> getKnownWordsCount(String userId);
  Future<int> getTodayLearnedCount(String userId);
  Future<Map<String, int>> getProgressByLevel(String userId);
  Future<void> syncLocalToRemote(String userId);
}
