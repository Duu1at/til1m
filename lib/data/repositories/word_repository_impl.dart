import 'package:flutter/foundation.dart';
import 'package:til1m/data/datasources/local/word_local_datasource.dart';
import 'package:til1m/data/datasources/remote/word_remote_datasource.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/repositories/word_repository.dart';

final class WordRepositoryImpl implements WordRepository {
  const WordRepositoryImpl({
    required WordRemoteDataSource remote,
    required WordLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final WordRemoteDataSource _remote;
  final WordLocalDataSource _local;

  @override
  Future<List<Word>> getWords({WordLevel? level, int? limit, int? offset}) async {
    try {
      final result = await _remote.fetchPage(
        offset: offset ?? 0,
        limit: limit ?? 50,
        level: level,
      );
      await _local.cacheWords(result.words);
      return result.words;
    } on Object catch (e, st) {
      debugPrint('[WordRepo] getWords remote failed, using cache: $e\n$st');
      final cached = await _local.fetchPage(
        offset: offset ?? 0,
        limit: limit ?? 50,
        level: level,
      );
      return cached.words;
    }
  }

  @override
  Future<Word?> getWordById(String id) async {
    try {
      final result = await _remote.fetchPage(
        offset: 0,
        limit: 1,
        inIds: [id],
      );
      return result.words.isEmpty ? null : result.words.first;
    } on Object catch (e, st) {
      debugPrint('[WordRepo] getWordById remote failed: $e\n$st');
      return null;
    }
  }

  @override
  Future<List<Word>> searchWords(String query) async {
    try {
      final result = await _remote.fetchPage(
        offset: 0,
        limit: 50,
        searchQuery: query,
      );
      return result.words;
    } on Object catch (e, st) {
      debugPrint('[WordRepo] searchWords remote failed, using cache: $e\n$st');
      final cached = await _local.fetchPage(
        offset: 0,
        limit: 50,
        searchQuery: query,
      );
      return cached.words;
    }
  }

  @override
  Future<Word?> getWordOfDay() async {
    try {
      final result = await _remote.fetchPage(offset: 0, limit: 1);
      return result.words.isEmpty ? null : result.words.first;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> cacheWords(List<Word> words) => _local.cacheWords(words);

  @override
  Future<List<Word>> getCachedWords({WordLevel? level}) async {
    final result = await _local.fetchPage(offset: 0, limit: 500, level: level);
    return result.words;
  }
}
