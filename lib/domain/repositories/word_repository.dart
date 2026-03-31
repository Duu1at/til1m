import 'package:wordup/domain/entities/word.dart';

abstract interface class WordRepository {
  Future<List<Word>> getWords({WordLevel? level, int? limit, int? offset});
  Future<Word?> getWordById(String id);
  Future<List<Word>> searchWords(String query);
  Future<Word?> getWordOfDay();
  Future<void> cacheWords(List<Word> words);
  Future<List<Word>> getCachedWords({WordLevel? level});
}
