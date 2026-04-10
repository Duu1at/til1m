import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/data/repositories/flashcard_repository_impl.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';

@immutable
class UpdateHomeWidget {
  const UpdateHomeWidget({
    required FlashcardRepositoryImpl flashcardRepo,
    required AuthRepository authRepo,
  }) : _repo = flashcardRepo,
       _authRepo = authRepo;

  final FlashcardRepositoryImpl _repo;
  final AuthRepository _authRepo;

  static const String _widgetName = AppConstants.widgetName;

  Future<void> call() async {
    try {
      if (_authRepo.currentUserId == null) return;
      final userId = _authRepo.currentUserId!;

      final prefs = await SharedPreferences.getInstance();
      final dailyGoal = prefs.getInt(AppConstants.keyDailyGoal) ?? 5;
      final levelRaw = prefs.getString(AppConstants.keyUserLevel) ?? 'a1';
      final level = WordLevel.values.firstWhere(
        (l) => l.name.toLowerCase() == levelRaw.toLowerCase(),
        orElse: () => WordLevel.a1,
      );

      final todayLearned = await _repo.getTodayLearnedCount(userId);
      final goalReached = todayLearned >= dailyGoal;

      final word = await _pickWord(userId, level);

      await Future.wait([
        HomeWidget.saveWidgetData<String>('widget_word', word?.word ?? ''),
        HomeWidget.saveWidgetData<String>(
          'widget_transcription',
          word?.transcriptionText ?? '',
        ),
        HomeWidget.saveWidgetData<String>(
          'widget_translation',
          word?.translationFor('ru') ?? word?.translationFor('ky') ?? '',
        ),
        HomeWidget.saveWidgetData<String>(
          'widget_progress',
          '$todayLearned из $dailyGoal',
        ),
        HomeWidget.saveWidgetData<bool>('widget_goal_reached', goalReached),
      ]);

      await HomeWidget.updateWidget(name: _widgetName);
    } on Object catch (e, st) {
      debugPrint('[UpdateHomeWidget] error (non-fatal): $e\n$st');
    }
  }

  Future<Word?> _pickWord(String userId, WordLevel level) async {
    try {
      final reviewItems = await _repo.getReviewSessionItems(userId);
      if (reviewItems.isNotEmpty) return reviewItems.first.word;
    } on Object catch (e) {
      debugPrint('[UpdateHomeWidget] getReviewSessionItems: $e');
    }

    try {
      final words = await _repo.getNewWords(
        level: level,
        excludeIds: const [],
        limit: 20,
      );
      if (words.isEmpty) return null;
      return words[Random().nextInt(words.length)];
    } on Object catch (e) {
      debugPrint('[UpdateHomeWidget] getNewWords: $e');
      return null;
    }
  }
}
