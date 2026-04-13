## Задача

Реализуй виджет рабочего стола для Flutter-приложения **TIl1m** (изучение английских слов). Используй пакет `home_widget`. Виджет должен работать на Android (AppWidgetProvider) и iOS (WidgetKit).

---

## Контекст проекта

Виджет показывает текущее слово из дневного набора пользователя прямо на рабочем столе телефона. Пользователь видит слово, транскрипцию(речь), перевод, изображение и прогресс — не открывая приложение.

---

## Стек для виджета

- `home_widget: ^0.7.0` — Flutter-пакет для виджетов
- `workmanager: ^0.5.0` — фоновое обновление (Android)
- `hive_flutter` — получение кэшированных данных
- `flutter_tts` — воспроизведение произношения при deep link
- Android: `AppWidgetProvider` + XML layout
- iOS: `WidgetKit` + SwiftUI

## Три размера виджета

### Маленький (2×2) — минимум информации

Показывает:

- Слово крупным шрифтом (например: **opportunity**)
- Транскрипция: /ˌɒp.əˈtʃuː.nɪ.ti/ и кнопка (речь)
- Перевод: возможность

При нажатии → открывается карточка этого слова в приложении (deep link).

### Средний (4×2) — слово + визуал + прогресс

Показывает:

- Слово + транскрипция(речь) + перевод (слева)
- Ассоциативное изображение (справа, 80×80dp)
- Прогресс-бар снизу: «3 из 5» с визуальной полоской
- Иконка 🔊 рядом с транскрипцией

При нажатии на слово → карточка слова.
При нажатии на 🔊 → открывается приложение и автоматически воспроизводится аудио.

### Большой (4×4) — полная карточка

Показывает:

- Слово крупно + часть речи (бейдж)
- Ассоциативное изображение (крупнее, ~120×120dp)
- Транскрипция(речь) + иконка 🔊
- Перевод (RU или KY в зависимости от настроек)
- Пример предложения: _"This is a great opportunity to learn."_
- Прогресс дня: «3 из 5 слов» + прогресс-бар
- Серия дней: «🔥 7 дней подряд»

При нажатии на слово → карточка слова.
При нажатии на 🔊 → воспроизведение аудио.
При нажатии на прогресс → главный экран приложения.

---

## Три состояния виджета

### Состояние 1 — В процессе обучения (по умолчанию)

Условие: дневная цель НЕ выполнена (learned < dailyGoal).

Отображает:

- Текущее слово из дневного набора
- Прогресс «3 из 5» + прогресс-бар (частично заполнен)
- Обычные цвета фона

### Состояние 2 — Цель достигнута

Условие: дневная цель выполнена (learned >= dailyGoal).

Отображает:

- Галочка ✔ + текст «Отлично!»
- Прогресс-бар полностью заполнен (зелёный)
- Серия дней: «🔥 7 дней подряд»
- Кнопка «Повторить слова» → deep link в режим повторения

### Состояние 3 — Режим повторения

Условие: цель достигнута + прошло 2+ часа.

Отображает:

- Метка «Повторение» сверху (другой цвет фона — мягкий жёлтый/оранжевый)
- Ранее изученное слово (случайное из known/learning)
- Транскрипция(речь) + перевод + изображение
- Кнопка «Открыть словарь» → deep link в словарь

**ВАЖНО: Виджет НИКОГДА не должен быть пустым. Если данных нет — показать заглушку «Откройте TIl1m чтобы начать учить слова» с логотипом.**

---

## Логика обновления виджета

### Когда обновлять

1. **При открытии приложения** — `WidgetsBindingObserver.didChangeAppLifecycleState` → обновить данные виджета
2. **После каждого ответа «Знаю»/«Не знаю»** — обновить прогресс на виджете
3. **По расписанию** — каждые 4–6 часов через WorkManager (Android) / BackgroundTasks (iOS)
4. **При смене дня** — сбросить прогресс, загрузить новые слова
5. **При достижении дневной цели** — переключить состояние на «Цель достигнута»

### Как обновлять (через home_widget)

```dart
class WidgetService {
  static Future<void> updateWidget({
    required Word word,
    required int learnedToday,
    required int dailyGoal,
    required int streakDays,
    required String widgetState, // "learning" | "completed" | "review"
  }) async {
    // Сохраняем данные в shared storage (доступно и Flutter, и нативному виджету)
    await HomeWidget.saveWidgetData('word', word.word);
    await HomeWidget.saveWidgetData('transcription', word.transcription);
    await HomeWidget.saveWidgetData('translation', word.translationRu);
    await HomeWidget.saveWidgetData('translation_ky', word.translationKy ?? '');
    await HomeWidget.saveWidgetData('part_of_speech', word.partOfSpeech);
    await HomeWidget.saveWidgetData('example_en', word.exampleEn ?? '');
    await HomeWidget.saveWidgetData('example_ru', word.exampleRu ?? '');
    await HomeWidget.saveWidgetData('image_url', word.imageUrl ?? '');
    await HomeWidget.saveWidgetData('audio_url', word.audioUrl ?? '');
    await HomeWidget.saveWidgetData('learned_today', learnedToday);
    await HomeWidget.saveWidgetData('daily_goal', dailyGoal);
    await HomeWidget.saveWidgetData('streak_days', streakDays);
    await HomeWidget.saveWidgetData('widget_state', widgetState);
    await HomeWidget.saveWidgetData('word_id', word.id);

    // Обновляем виджет на экране
    await HomeWidget.updateWidget(
      androidName: 'TilimWidgetProvider',
      iOSName: 'TilimWidget',
    );
  }

  // Определение состояния
  static String getWidgetState(int learnedToday, int dailyGoal, DateTime? goalCompletedAt) {
    if (learnedToday < dailyGoal) return 'learning';
    if (goalCompletedAt != null &&
        DateTime.now().difference(goalCompletedAt).inHours >= 2) return 'review';
    return 'completed';
  }
}
```

---

## Deep Linking

Виджет должен поддерживать deep link для разных действий:

```dart
// В main.dart — обработка deep link от виджета
HomeWidget.widgetClicked.listen((Uri? uri) {
  if (uri == null) return;

  switch (uri.host) {
    case 'word':
      // Открыть карточку слова
      final wordId = uri.queryParameters['id'];
      router.go('/word/$wordId');
      break;
    case 'audio':
      // Открыть приложение и воспроизвести аудио
      final audioUrl = uri.queryParameters['url'];
      final wordId = uri.queryParameters['id'];
      router.go('/word/$wordId');
      AudioService.play(audioUrl!);
      break;
    case 'home':
      router.go('/home');
      break;
    case 'dictionary':
      router.go('/dictionary');
      break;
    case 'review':
      router.go('/flashcards?mode=review');
      break;
  }
});
```

URI-схемы для виджета:

- `tilim://word?id=<wordId>` — открыть карточку слова
- `tilim://audio?id=<wordId>&url=<audioUrl>` — воспроизвести аудио + открыть карточку
- `tilim://home` — главный экран
- `tilim://dictionary` — словарь
- `tilim://review` — режим повторения

---

## Android — нативная часть

### android/app/src/main/java/.../TilimWidgetProvider.kt

```kotlin
class TilimWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)

            // Выбор layout по размеру
            val layoutId = when {
                minWidth >= 250 -> R.layout.widget_large    // 4×4
                minWidth >= 180 -> R.layout.widget_medium   // 4×2
                else -> R.layout.widget_small               // 2×2
            }

            val views = RemoteViews(context.packageName, layoutId).apply {
                val word = widgetData.getString("word", "TIl1m") ?: "TIl1m"
                val transcription = widgetData.getString("transcription", "") ?: ""
                val translation = widgetData.getString("translation", "") ?: ""
                val widgetState = widgetData.getString("widget_state", "learning") ?: "learning"
                val learned = widgetData.getInt("learned_today", 0)
                val goal = widgetData.getInt("daily_goal", 5)
                val streak = widgetData.getInt("streak_days", 0)
                val exampleEn = widgetData.getString("example_en", "") ?: ""
                val wordId = widgetData.getString("word_id", "") ?: ""

                // Устанавливаем данные в layout
                setTextViewText(R.id.widget_word, word)
                setTextViewText(R.id.widget_transcription, transcription)
                setTextViewText(R.id.widget_translation, translation)
                setTextViewText(R.id.widget_progress, "$learned из $goal")

                // Состояния
                when (widgetState) {
                    "completed" -> {
                        setTextViewText(R.id.widget_word, "✔ Отлично!")
                        setTextViewText(R.id.widget_translation, "🔥 $streak дней подряд")
                        setViewVisibility(R.id.widget_review_btn, View.VISIBLE)
                    }
                    "review" -> {
                        setTextViewText(R.id.widget_label, "Повторение")
                        setViewVisibility(R.id.widget_label, View.VISIBLE)
                    }
                    else -> {
                        setViewVisibility(R.id.widget_label, View.GONE)
                        setViewVisibility(R.id.widget_review_btn, View.GONE)
                    }
                }

                // Пример (только для большого виджета)
                if (layoutId == R.layout.widget_large && exampleEn.isNotEmpty()) {
                    setTextViewText(R.id.widget_example, exampleEn)
                    setViewVisibility(R.id.widget_example, View.VISIBLE)
                }

                // Deep link — тап по слову
                val wordIntent = HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java,
                    Uri.parse("tilim://word?id=$wordId")
                )
                setOnClickPendingIntent(R.id.widget_word_area, wordIntent)

                // Deep link — тап по аудио
                val audioUrl = widgetData.getString("audio_url", "") ?: ""
                val audioIntent = HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java,
                    Uri.parse("tilim://audio?id=$wordId&url=$audioUrl")
                )
                setOnClickPendingIntent(R.id.widget_audio_btn, audioIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
```

### XML-layouts для виджета — создай 3 файла:

**android/app/src/main/res/layout/widget_small.xml** — слово, транскрипция, перевод. Фон: скруглённый белый/тёмный. Шрифт слова: 18sp bold. Транскрипция: 12sp серый. Перевод: 14sp.

**android/app/src/main/res/layout/widget_medium.xml** — слева: слово + транскрипция + перевод + прогресс-бар. Справа: ImageView для изображения. Иконка 🔊 рядом с транскрипцией (кликабельная).

**android/app/src/main/res/layout/widget_large.xml** — сверху: слово + бейдж части речи. Под ним: изображение. Транскрипция + 🔊. Перевод. Пример предложения (курсив, серый). Прогресс-бар + серия дней. Метка «Повторение» (скрыта по умолчанию). Кнопка «Повторить слова» (скрыта по умолчанию).

### Дизайн виджета

- Фон: скруглённый прямоугольник (cornerRadius 16dp)
- Светлая тема: белый фон (#FFFFFF), тёмный текст
- Тёмная тема: тёмно-серый фон (#1E1E2E), светлый текст
- Шрифт слова: жирный, крупный
- Транскрипция: серый цвет, моноширинный
- Прогресс-бар: синий (#1F4E8C) на сером (#E0E0E0)
- Состояние «completed»: зелёный прогресс-бар (#4CAF50)
- Состояние «review»: мягкий оранжевый фон (#FFF3E0)

---

## iOS — нативная часть (WidgetKit + SwiftUI)

Создай WidgetExtension с тремя family:

- `.systemSmall` — маленький
- `.systemMedium` — средний
- `.systemLarge` — большой

```swift
struct TilimWidgetEntry: TimelineEntry {
    let date: Date
    let word: String
    let transcription: String
    let translation: String
    let translationKy: String
    let partOfSpeech: String
    let exampleEn: String
    let imageUrl: String
    let audioUrl: String
    let learnedToday: Int
    let dailyGoal: Int
    let streakDays: Int
    let widgetState: String // "learning" | "completed" | "review"
    let wordId: String
}
```

Используй `UserDefaults(suiteName: "group.com.tilim.app")` для чтения данных, которые Flutter записывает через home_widget.

Timeline refresh policy: `.after(Date().addingTimeInterval(4 * 3600))` — обновление каждые 4 часа.

Deep link через `widgetURL` и `Link` в SwiftUI:

```swift
Link(destination: URL(string: "tilim://word?id=\(entry.wordId)")!) {
    // содержимое виджета
}
```

---

## Фоновое обновление

### Android — WorkManager

```dart
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Hive.initFlutter();
    // Получить текущее слово из Hive
    // Обновить виджет через WidgetService.updateWidget()
    return true;
  });
}

// Регистрация при старте приложения:
Workmanager().registerPeriodicTask(
  'widget-update',
  'updateWidget',
  frequency: Duration(hours: 4),
  constraints: Constraints(networkType: NetworkType.not_required),
);
```

### iOS — BackgroundTasks

Настроить в Info.plist BGTaskSchedulerPermittedIdentifiers и использовать BGAppRefreshTask.

---

## Кэширование изображений для виджета

Изображения из Supabase Storage нужно кэшировать локально, потому что нативный виджет не может загружать из сети напрямую.

```dart
Future<String?> cacheImageForWidget(String imageUrl) async {
  final response = await http.get(Uri.parse(imageUrl));
  if (response.statusCode == 200) {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/widget_image.png');
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }
  return null;
}
```

Передавай локальный путь в виджет:

```dart
await HomeWidget.saveWidgetData('image_path', localImagePath);
```

---

## Файлы которые нужно создать

### Flutter (lib/)

1. `lib/services/widget_service.dart` — логика обновления виджета
2. `lib/services/widget_background_service.dart` — фоновое обновление через WorkManager

### Android (android/)

3. `android/app/src/main/kotlin/.../TilimWidgetProvider.kt`
4. `android/app/src/main/res/layout/widget_small.xml`
5. `android/app/src/main/res/layout/widget_medium.xml`
6. `android/app/src/main/res/layout/widget_large.xml`
7. `android/app/src/main/res/xml/widget_small_info.xml`
8. `android/app/src/main/res/xml/widget_medium_info.xml`
9. `android/app/src/main/res/xml/widget_large_info.xml`
10. `android/app/src/main/res/drawable/widget_background.xml` — фон виджета
11. Обновить `android/app/src/main/AndroidManifest.xml` — зарегистрировать receiver

### iOS (ios/)

12. `ios/TilimWidget/TilimWidget.swift` — SwiftUI виджет
13. `ios/TilimWidget/TilimWidgetBundle.swift`
14. Обновить `ios/Podfile` — настроить App Group
15. Обновить Xcode проект — добавить Widget Extension target

---

## Начни реализацию

1. Установи зависимости: `home_widget`, `workmanager`
2. Создай `WidgetService` в Flutter
3. Создай Android XML layouts для 3 размеров
4. Создай `TilimWidgetProvider.kt`
5. Зарегистрируй виджет в AndroidManifest.xml
6. Создай iOS WidgetExtension (SwiftUI)
7. Реализуй deep linking для тапов
8. Настрой фоновое обновление через WorkManager
9. Протестируй все 3 состояния и все 3 размера
