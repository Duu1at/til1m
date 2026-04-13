import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/data/repositories/flashcard_repository_impl.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';

final class PrefetchFlashcardData {
  const PrefetchFlashcardData({
    required FlashcardRepositoryImpl flashcardRepo,
    required AuthRepository authRepo,
  }) : _repo = flashcardRepo,
       _authRepo = authRepo;

  final FlashcardRepositoryImpl _repo;
  final AuthRepository _authRepo;

  Future<void> call() async {
    if (_authRepo.currentUserId == null) return;
    final userId = _authRepo.currentUserId!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyGoal = prefs.getInt(AppConstants.keyDailyGoal) ?? 5;
      final levelRaw = prefs.getString(AppConstants.keyUserLevel) ?? 'a1';
      final level = WordLevel.values.firstWhere(
        (l) => l.name.toLowerCase() == levelRaw.toLowerCase(),
        orElse: () => WordLevel.a1,
      );

      final reviewItems = await _repo.getReviewSessionItems(userId);
      debugPrint(
        '[PrefetchFlashcardData] cached ${reviewItems.length} review words',
      );

      final alreadyTrackedIds = await _repo.getProgressWordIds(userId);
      final newWords = await _repo.getNewWords(
        level: level,
        excludeIds: alreadyTrackedIds,
        limit: dailyGoal * 3,
      );
      debugPrint(
        '[PrefetchFlashcardData] cached ${newWords.length} new words',
      );

      final allWords = [
        ...reviewItems.map((i) => i.word),
        ...newWords,
      ];
      await _precacheImages(allWords);
    } on Object catch (e, st) {
      debugPrint('[PrefetchFlashcardData] error (non-fatal): $e\n$st');
    }
  }

  Future<void> _precacheImages(List<Word> words) async {
    var precached = 0;
    for (final word in words) {
      final url = word.imageUrl;
      if (url == null || url.isEmpty) continue;
      try {
        await CachedNetworkImageProvider(url).obtainKey(
          ImageConfiguration.empty,
        );
        precached++;
      } on Object catch (e) {
        debugPrint('[PrefetchFlashcardData] image precache failed ($url): $e');
      }
    }
    debugPrint('[PrefetchFlashcardData] precached $precached images');
  }
}
