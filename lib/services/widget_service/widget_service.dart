import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/domain/entities/word.dart';

/// Determines the current widget display state.
enum WidgetState {
  /// Daily goal not yet reached — show current learning word.
  learning,

  /// Daily goal reached, < 2 hours ago — show completion screen.
  completed,

  /// Daily goal reached, 2+ hours ago — show a review word.
  review,
}

/// Service responsible for updating the home-screen widget data via the
/// home_widget package. All Supabase / Hive access is done upstream; this
/// class only saves data to shared storage and triggers a widget refresh.
@immutable
final class WidgetService {
  const WidgetService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // Provider names are stored in AppConstants to keep callbackDispatcher in sync.

  // ── Public API ────────────────────────────────────────────────────────────

  /// Push [word] and progress data to the widget shared storage and repaint.
  Future<void> updateWidget({
    required Word word,
    required int learnedToday,
    required int dailyGoal,
    required int streakDays,
    required WidgetState widgetState,
    String uiLanguage = 'ru',
  }) async {
    try {
      final translationRu = word.translationFor('ru') ?? '';
      final translationKy = word.translationFor('ky') ?? '';
      final translation =
          uiLanguage == 'ky' && translationKy.isNotEmpty
              ? translationKy
              : translationRu;

      final exampleEn = word.examples.isNotEmpty
          ? word.examples.first.exampleEn
          : '';
      final exampleRu = word.examples.isNotEmpty
          ? (word.examples.first.exampleRu ?? '')
          : '';

      // Cache image locally so the native widget can load it without network.
      final imagePath =
          word.imageUrl != null ? await _cacheImage(word.imageUrl!) : '';

      await Future.wait([
        HomeWidget.saveWidgetData<String>('word', word.word),
        HomeWidget.saveWidgetData<String>(
          'transcription',
          word.transcriptionText ?? '',
        ),
        HomeWidget.saveWidgetData<String>('translation', translation),
        HomeWidget.saveWidgetData<String>('translation_ky', translationKy),
        HomeWidget.saveWidgetData<String>(
          'part_of_speech',
          word.partOfSpeech.label,
        ),
        HomeWidget.saveWidgetData<String>('example_en', exampleEn),
        HomeWidget.saveWidgetData<String>('example_ru', exampleRu),
        HomeWidget.saveWidgetData<String>('image_path', imagePath),
        HomeWidget.saveWidgetData<String>('audio_url', word.audioUrl ?? ''),
        HomeWidget.saveWidgetData<int>('learned_today', learnedToday),
        HomeWidget.saveWidgetData<int>('daily_goal', dailyGoal),
        HomeWidget.saveWidgetData<int>('streak_days', streakDays),
        HomeWidget.saveWidgetData<String>(
          'widget_state',
          widgetState.name,
        ),
        HomeWidget.saveWidgetData<String>('word_id', word.id),
        HomeWidget.saveWidgetData<String>(
          'level',
          word.level.label,
        ),
        // ── Localised UI strings ──────────────────────────────────────────
        // Native layers read these keys and display them directly, so the
        // widget supports RU / KY / EN without any hardcoded text.
        HomeWidget.saveWidgetData<String>(
          'completed_title',
          _loc(ru: '✔ Отлично!', ky: '✔ Мыкты!', en: '✔ Great!', lang: uiLanguage),
        ),
        HomeWidget.saveWidgetData<String>(
          'progress_text',
          _progressText(learnedToday, dailyGoal, uiLanguage),
        ),
        HomeWidget.saveWidgetData<String>(
          'streak_text',
          _streakText(streakDays, uiLanguage),
        ),
        HomeWidget.saveWidgetData<String>(
          'label_review',
          _loc(ru: 'Повторение', ky: 'Кайталоо', en: 'Review', lang: uiLanguage),
        ),
        HomeWidget.saveWidgetData<String>(
          'label_review_btn',
          _loc(ru: 'Повторить слова', ky: 'Сөздөрдү кайталоо', en: 'Review words', lang: uiLanguage),
        ),
        HomeWidget.saveWidgetData<String>(
          'label_empty',
          _loc(
            ru: 'Откройте TIl1m чтобы начать учить слова',
            ky: 'Сөз үйрөнүүнү баштоо үчүн TIl1m ачыңыз',
            en: 'Open TIl1m to start learning',
            lang: uiLanguage,
          ),
        ),
      ]);

      await _refreshNativeWidget();
    } on Object catch (e, st) {
      debugPrint('[WidgetService] updateWidget error (non-fatal): $e\n$st');
    }
  }

  /// Show the empty / placeholder state when no word data is available.
  Future<void> showEmptyState({String uiLanguage = 'ru'}) async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>('word', ''),
        HomeWidget.saveWidgetData<String>('widget_state', 'empty'),
        HomeWidget.saveWidgetData<String>(
          'label_empty',
          _loc(
            ru: 'Откройте TIl1m чтобы начать учить слова',
            ky: 'Сөз үйрөнүүнү баштоо үчүн TIl1m ачыңыз',
            en: 'Open TIl1m to start learning',
            lang: uiLanguage,
          ),
        ),
      ]);
      await _refreshNativeWidget();
    } on Object catch (e, st) {
      debugPrint('[WidgetService] showEmptyState error (non-fatal): $e\n$st');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Trigger a repaint on every registered Android provider and the iOS widget.
  /// Must be called after all `saveWidgetData` writes are complete.
  Future<void> _refreshNativeWidget() async {
    for (final name in AppConstants.androidWidgetProviders) {
      await HomeWidget.updateWidget(
        androidName: name,
        iOSName: AppConstants.iosWidgetName,
        qualifiedAndroidName: '${AppConstants.androidWidgetPackage}.$name',
      );
    }
  }

  /// Download [imageUrl] to app-documents directory and return local path.
  /// Returns empty string on failure.
  Future<String> _cacheImage(String imageUrl) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/widget_image.png';
      await _dio.download(imageUrl, filePath);
      return filePath;
    } on Object catch (e) {
      debugPrint('[WidgetService] image cache error (non-fatal): $e');
    }
    return '';
  }

  // ── Static utilities ──────────────────────────────────────────────────────

  /// Return the string matching [lang], falling back to Russian.
  static String _loc({
    required String ru,
    required String ky,
    required String en,
    required String lang,
  }) =>
      switch (lang) { 'ky' => ky, 'en' => en, _ => ru };

  /// Localised "X of Y words" string. Caps displayed count at [goal].
  static String _progressText(int learned, int goal, String lang) {
    final shown = learned.clamp(0, goal);
    return switch (lang) {
      'ky' => '$shown / $goal сөз',
      'en' => '$shown of $goal words',
      _ => '$shown из $goal слов',
    };
  }

  /// Localised "🔥 N days streak" string.
  static String _streakText(int days, String lang) => switch (lang) {
        'ky' => '🔥 $days күн катары',
        'en' => '🔥 $days days',
        _ => '🔥 $days дней подряд',
      };

  /// Determine the widget display state from progress counters and timestamps.
  static WidgetState getWidgetState({
    required int learnedToday,
    required int dailyGoal,
    DateTime? goalCompletedAt,
  }) {
    if (learnedToday < dailyGoal) return WidgetState.learning;
    if (goalCompletedAt != null &&
        DateTime.now().difference(goalCompletedAt).inHours >= 2) {
      return WidgetState.review;
    }
    return WidgetState.completed;
  }

  /// Register this app as the home_widget data provider (call once at startup).
  static Future<void> setAppGroupId() async {
    await HomeWidget.setAppGroupId(AppConstants.widgetGroupId);
  }
}
