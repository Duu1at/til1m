## ПРОМПТ 0 — Контекст проекта (вставить один раз в начале сессии)

```
Ты работаешь над Flutter-приложением Til1m для изучения английских слов.

Стек: Flutter (Dart), Supabase (PostgreSQL + Auth + Storage), BLoC/Cubit (flutter_bloc), Hive (офлайн-кэш), home_widget.

Структура проекта (Clean Architecture):
lib/
├── core/              # Константы, тема, утилиты, ошибки
├── data/
│   ├── models/        # Модели данных (fromJson/toJson)
│   ├── datasources/   # Remote (Supabase) + Local (Hive)
│   └── repositories/  # Имплементации репозиториев
├── domain/
│   ├── entities/       # Чистые сущности
│   ├── repositories/   # Абстрактные репозитории (интерфейсы)
│   └── usecases/       # Бизнес-логика
├── presentation/
│   ├── blocs/          # BLoC / Cubit
│   ├── screens/        # Экраны
│   └── widgets/        # Переиспользуемые виджеты
└── main.dart

БД Supabase — таблицы:
- words (id, word, transcription_text, audio_url, image_url, level, part_of_speech)
- word_translations (id, word_id, language [ru/ky], translation, synonyms[])
- word_examples (id, word_id, example_en, example_ru, example_ky, order_index)
- user_word_progress (id, user_id, word_id, status [new/learning/known], next_review_at, ease_factor, repetitions, last_reviewed_at)
- user_settings (user_id, daily_goal, english_level, ui_language, reminder_time, theme)
- user_favorites (user_id, word_id, added_at)

```

---

## ПРОМПТ 1 — Сущности и модели Flashcards

```
Создай domain-сущности и data-модели для модуля Flashcards.

### 1. Domain Entities (lib/domain/entities/)

Файл: flashcard_word.dart
Класс FlashcardWord:
- id (String)
- word (String)
- transcriptionText (String)
- audioUrl (String?)
- imageUrl (String?)
- level (WordLevel enum: a1, a2, b1, b2, c1, c2)
- partOfSpeech (PartOfSpeech enum: noun, verb, adjective, adverb, phrase)
- translations (List<Translation>) — перевод RU/KY
- examples (List<WordExample>) — примеры предложений

Файл: translation.dart
Класс Translation:
- language (TranslationLanguage enum: ru, ky)
- translation (String)
- synonyms (List<String>)

Файл: word_example.dart
Класс WordExample:
- exampleEn (String)
- exampleRu (String)
- exampleKy (String)

Файл: word_progress.dart
Класс WordProgress:
- wordId (String)
- status (WordStatus enum: newWord, learning, known)
- nextReviewAt (DateTime?)
- easeFactor (double, default 2.5)
- repetitions (int, default 0)
- lastReviewedAt (DateTime?)

Файл: flashcard_session.dart
Класс FlashcardSession:
- words (List<FlashcardWord>) — полная очередь
- currentIndex (int)
- reviewWords (List<FlashcardWord>) — слова на повторение
- newWords (List<FlashcardWord>) — новые слова
- failedWords (List<String>) — id слов с ответом "Не знаю" (вернутся в конец)
- sessionStartedAt (DateTime)
- answeredCount (int)
- correctCount (int)

### 2. Data Models (lib/data/models/)

Для каждой сущности создай модель с:
- fromJson(Map<String, dynamic>) — парсинг из Supabase
- toJson() — сериализация
- fromEntity() / toEntity() — конвертация
- fromHive(Map) / toHive() — для локального хранения

Используй Equatable для сущностей.
Не используй code generation (build_runner, freezed). Пиши вручную.
```

---

## ПРОМПТ 2 — Алгоритм SM-2

```
Создай use case для алгоритма интервального повторения SM-2.

Файл: lib/domain/usecases/calculate_sm2.dart

Класс CalculateSm2 — чистая функция без зависимостей:

Метод: Sm2Result calculate({required WordProgress current, required bool isCorrect})

Логика SM-2:

Если isCorrect == true:
  - Если repetitions == 0 → interval = 1 день
  - Если repetitions == 1 → interval = 6 дней
  - Если repetitions >= 2 → interval = (предыдущий интервал * easeFactor).round()
  - repetitions += 1
  - easeFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    где quality = 4 (для "Знаю")
  - easeFactor не может быть меньше 1.3
  - status = repetitions >= 3 ? known : learning
  - nextReviewAt = now + interval дней

Если isCorrect == false:
  - repetitions = 0
  - interval = 0 (повторить сегодня)
  - easeFactor = max(1.3, easeFactor - 0.2)
  - status = learning
  - nextReviewAt = now (слово вернётся в конец очереди текущей сессии)

Sm2Result содержит:
- updatedProgress (WordProgress)
- interval (int, дни)
- returnToQueue (bool — true если "Не знаю", слово идёт в конец сессии)

Напиши юнит-тесты в test/domain/usecases/calculate_sm2_test.dart:
- Новое слово + "Знаю" → interval 1, repetitions 1, status learning
- Слово с 1 повторением + "Знаю" → interval 6, repetitions 2
- Слово с 2+ повторениями + "Знаю" → interval умножается на easeFactor
- Любое слово + "Не знаю" → repetitions 0, returnToQueue true
- easeFactor никогда не ниже 1.3
```

---

## ПРОМПТ 3 — Формирование очереди Flashcards

```
Создай use case для формирования очереди слов на сессию Flashcards.

Файл: lib/domain/usecases/build_flashcard_queue.dart

Класс BuildFlashcardQueue:
  Зависимости (через конструктор):
  - WordRepository (абстрактный)
  - ProgressRepository (абстрактный)
  - SettingsRepository (абстрактный)

Метод: Future<FlashcardSession> call({FlashcardSource source})

enum FlashcardSource { daily, reviewOnly, favorites, specificLevel(WordLevel) }

Логика формирования очереди по source:

### daily (основной режим):
1. Получить настройки пользователя (daily_goal, english_level)
2. Загрузить слова на повторение: status = learning, next_review_at <= now
   Сортировка: самые просроченные первыми
3. Загрузить новые слова: status = new, level = english_level
   Количество: daily_goal - (количество уже изученных за сегодня)
   Если <= 0, новые не добавляются
4. Объединить: сначала повторение, потом новые
5. Создать FlashcardSession

### reviewOnly:
- Только слова с next_review_at <= now, без ограничения по количеству
- Если очередь пуста → вернуть пустую сессию (UI покажет "Нет слов на повторение")

### favorites:
- Только слова из user_favorites
- Перемешать (shuffle)

### specificLevel:
- Все слова указанного уровня, перемешать

Также создай абстрактные репозитории:

lib/domain/repositories/word_repository.dart:
- Future<List<FlashcardWord>> getWordsByLevel(WordLevel level, {int? limit})
- Future<List<FlashcardWord>> getWordsForReview(DateTime now)
- Future<List<FlashcardWord>> getFavoriteWords(String userId)
- Future<FlashcardWord> getWordById(String id)

lib/domain/repositories/progress_repository.dart:
- Future<WordProgress?> getProgress(String wordId)
- Future<void> saveProgress(WordProgress progress)
- Future<int> getTodayLearnedCount()
- Future<List<WordProgress>> getAllProgress()

lib/domain/repositories/settings_repository.dart:
- Future<UserSettings> getSettings()
- Future<void> saveSettings(UserSettings settings)
```

---

## ПРОМПТ 4 — Репозитории (Supabase + Hive)

```
Создай имплементации репозиториев для модуля Flashcards.
Каждый репозиторий работает в двух режимах: онлайн (Supabase + кэш Hive) и гость (только Hive).

### Remote DataSource (lib/data/datasources/remote/)

Файл: flashcard_remote_datasource.dart
- Все методы через Supabase client
- getWordsForReview: SELECT из words JOIN user_word_progress WHERE next_review_at <= now AND user_id = current
- getWordsByLevel: SELECT из words WHERE level = ? с JOIN на translations и examples
- Используй .select() с join-запросами Supabase:
  supabase.from('words').select('*, word_translations(*), word_examples(*)').eq('level', level)
- saveProgress: UPSERT в user_word_progress

### Local DataSource (lib/data/datasources/local/)

Файл: flashcard_local_datasource.dart
- Hive box 'words_cache' — кэш слов (Map<String, dynamic>)
- Hive box 'progress' — прогресс пользователя (Map<String, dynamic>)
- Hive box 'session_state' — состояние текущей сессии (для восстановления при закрытии)
- cacheWords(List<WordModel> words) — сохранить в Hive
- getCachedWords() — получить из Hive
- saveSessionState(FlashcardSessionModel session) — сохранить текущую сессию
- getSessionState() — восстановить сессию после закрытия
- clearSessionState() — очистить при завершении сессии

### Repository Implementation (lib/data/repositories/)

Файл: flashcard_repository_impl.dart
Реализует WordRepository и ProgressRepository.

Логика:
- Если пользователь авторизован → Supabase с кэшем в Hive
- Если гость → только Hive
- Определять через AuthRepository.isGuest
- При ошибке сети → fallback на Hive
- При синхронизации (гость → аккаунт) → merge локальных данных в Supabase

try-catch на все Supabase-вызовы. При сетевой ошибке — вернуть кэш.
```

---

## ПРОМПТ 5 — BLoC для Flashcards

```
Создай BLoC для управления сессией Flashcards.

Файл: lib/presentation/blocs/flashcard/flashcard_bloc.dart
Файл: lib/presentation/blocs/flashcard/flashcard_event.dart
Файл: lib/presentation/blocs/flashcard/flashcard_state.dart

### Events:

FlashcardEvent (sealed class):
- FlashcardStartSession({required FlashcardSource source})
  → Начать новую сессию. Формирует очередь.
- FlashcardResumeSession()
  → Восстановить сессию из Hive после закрытия приложения.
- FlashcardFlipCard()
  → Перевернуть текущую карточку (показать перевод).
- FlashcardAnswer({required bool isCorrect})
  → Пользователь нажал "Знаю" или "Не знаю".
- FlashcardUndo()
  → Отменить последний ответ (вернуть предыдущую карточку).
- FlashcardSkip()
  → Пропустить слово (не влияет на SM-2, перейти к следующему).
- FlashcardPlayAudio()
  → Воспроизвести аудио текущего слова.
- FlashcardEndSession()
  → Завершить сессию досрочно. Сохранить прогресс.
- FlashcardLoadMore()
  → Подгрузить дополнительные слова (когда очередь закончилась, но пользователь хочет ещё).

### States:

FlashcardState (sealed class):
- FlashcardInitial()
- FlashcardLoading()
- FlashcardActive({
    required FlashcardWord currentWord,
    required bool isFlipped,         // показана ли обратная сторона
    required int currentIndex,       // текущая позиция в очереди
    required int totalWords,         // всего слов в сессии
    required int answeredCount,      // сколько уже ответил
    required int correctCount,       // сколько "Знаю"
    required int reviewCount,        // сколько слов на повторение было
    required int newCount,           // сколько новых слов было
    required bool canUndo,           // можно ли отменить последний ответ
    required bool isAudioPlaying,
  })
- FlashcardSessionComplete({
    required int totalAnswered,
    required int correctCount,
    required int incorrectCount,
    required int newWordsLearned,
    required int wordsReviewed,
    required Duration sessionDuration,
    required bool dailyGoalReached,  // выполнена ли дневная цель
    required int currentStreak,
  })
- FlashcardEmpty({required FlashcardSource source})
  // Нет слов для изучения (очередь пуста)
- FlashcardError({required String message})

### Логика в BLoC:

При FlashcardAnswer(isCorrect: true):
1. Вызвать CalculateSm2.calculate()
2. Сохранить обновлённый прогресс через ProgressRepository
3. Перейти к следующему слову
4. Если слов больше нет → emit FlashcardSessionComplete
5. Сохранить состояние сессии в Hive

При FlashcardAnswer(isCorrect: false):
1. Вызвать CalculateSm2.calculate()
2. Сохранить прогресс
3. Добавить слово в конец очереди (failedWords)
4. Если слово уже ошибалось 3+ раз в сессии → НЕ добавлять снова, показать hint
5. Перейти к следующему слову

При FlashcardUndo:
1. Хранить стек последних действий (List<UndoAction>)
2. Откатить прогресс последнего слова
3. Вернуться к предыдущей карточке

При FlashcardResumeSession:
1. Загрузить состояние из Hive (session_state box)
2. Если есть — восстановить и emit FlashcardActive
3. Если нет — emit FlashcardInitial

Не забудь:
- close() в BLoC: сохранить состояние в Hive перед закрытием
- Аудио: использовать flutter_tts(даем слов flutter_tts делает нам речь), обрабатывать ошибки загрузки
```

---

## ПРОМПТ 6 — UI экрана Flashcards

```
Создай экран Flashcards с анимациями.

### Файлы:

lib/presentation/screens/flashcard_screen.dart — основной экран
lib/presentation/widgets/flashcard/flashcard_card.dart — карточка с анимацией переворота
lib/presentation/widgets/flashcard/flashcard_progress_bar.dart — прогресс сессии
lib/presentation/widgets/flashcard/flashcard_result_screen.dart — экран результатов
lib/presentation/widgets/flashcard/flashcard_empty_screen.dart — пустая очередь

### FlashcardScreen:

Структура:
- AppBar: кнопка "Закрыть" (←) + заголовок "Flashcards" + кнопка пропуска
- FlashcardProgressBar сверху: "5/12" + линейный прогресс-бар
- По центру: FlashcardCard (занимает основное пространство)
- Снизу: кнопки действий

BlocBuilder<FlashcardBloc, FlashcardState> — переключение между состояниями.

### FlashcardCard (анимация переворота):

Лицевая сторона:
- Изображение слова (сверху, CachedNetworkImage с placeholder)
- Слово крупным шрифтом (28sp, bold)
- Транскрипция IPA (16sp, серый цвет)
- Кнопка аудио 🔊 (IconButton, воспроизводит произношение)
- Кнопка "Показать ответ" снизу

Обратная сторона:
- Перевод на RU / KY (в зависимости от настройки, переключаемые вкладки если "Оба")
- Часть речи (бейдж: noun / verb / adj...)
- Уровень (бейдж: A1-C2)
- 2-3 примера предложений (английский + перевод)
- Кнопки: "Не знаю" (красная, слева) и "Знаю" (зелёная, справа)

Анимация переворота:
- AnimationController + Transform (Matrix4.rotationY)
- Длительность: 400ms, Curves.easeInOut
- При повороте на 90° — переключить содержимое (front/back)
- Также поддержать вертикальный свайп вверх для переворота (GestureDetector)

Свайп-жесты:
- Свайп вправо → "Знаю" (зелёная подсветка)
- Свайп влево → "Не знаю" (красная подсветка)
- Свайп вверх → перевернуть карточку
- При свайпе: карточка наклоняется в сторону свайпа (Transform.rotate)
- Цветной оверлей: зелёный/красный с opacity пропорционально смещению

### FlashcardProgressBar:
- Текст "5 из 12"
- LinearProgressIndicator с анимацией
- Зелёный цвет для пройденных, серый для оставшихся

### FlashcardResultScreen (когда сессия завершена):
- Иконка/анимация (Lottie или кастомная: конфетти если все правильно, подбадривание если были ошибки)
- Статистика:
  - "Изучено слов: 12"
  - "Правильно: 10 (83%)"
  - "Новых слов: 5"
  - "Повторено: 7"
  - "Время сессии: 4 мин"
- Бейдж если дневная цель выполнена: "🔥 Streak: 5 дней!"
- Кнопки: "Учить ещё" / "На главную"

### FlashcardEmptyScreen (нет слов):
- Иллюстрация (placeholder SVG)
- Текст зависит от source:
  - daily: "Все слова на сегодня пройдены! Приходи завтра или учи ещё"
  - reviewOnly: "Нет слов на повторение. Ты молодец!"
  - favorites: "Добавь слова в избранное, чтобы учить их здесь"
- Кнопка "Учить новые слова" (подгрузить дополнительные)

Используй:
- Theme.of(context) для цветов и текстовых стилей
- Responsive: MediaQuery для адаптации под разные размеры экранов
- Hero-анимацию для перехода из списка слов в карточку (если применимо)
```

---

## ПРОМПТ 7 — Офлайн-режим и кэширование

```
Реализуй офлайн-режим для Flashcards.

### Задачи:

1. Предзагрузка данных (lib/domain/usecases/prefetch_flashcard_data.dart):
   - При открытии приложения (или при наличии Wi-Fi) предзагрузить:
     - Слова на повторение (next_review_at <= завтра, с запасом)
     - Новые слова (daily_goal * 3, чтобы было на 3 дня вперёд)
     - Аудио-файлы этих слов → скачать и сохранить в локальный кэш
     - Изображения → CachedNetworkImage уже кэширует, но добавить precache
   - Сохранить в Hive box 'words_cache'

2. Определение состояния сети (lib/core/network/connectivity_service.dart):
   - Использовать пакет connectivity_plus
   - Stream<bool> isOnline — подписка на изменение состояния
   - При потере сети → переключиться на Hive
   - При восстановлении → синхронизировать прогресс

3. Синхронизация прогресса (lib/data/datasources/sync/progress_sync_service.dart):
   - При офлайн: все ответы "Знаю"/"Не знаю" сохраняются в Hive box 'pending_sync'
   - Каждая запись: {wordId, isCorrect, answeredAt, updatedProgress}
   - При появлении интернета:
     а) Загрузить pending_sync из Hive
     б) Отправить batch UPSERT в Supabase (user_word_progress)
     в) При успехе — очистить pending_sync
     г) При конфликте (progress.lastReviewedAt на сервере новее) — сервер побеждает
   - Показать SnackBar: "Прогресс синхронизирован" / "Ошибка синхронизации"

4. Обновление Hive box 'session_state':
   - При каждом ответе — сохранять текущее состояние сессии
   - При закрытии приложения — session_state уже актуален
   - При открытии — проверить session_state, предложить продолжить

Правила:
- Гостевой режим: pending_sync не нужен (данные всегда локальные)
- Аудио офлайн: если файл не скачан → скрыть кнопку аудио, не показывать ошибку
- Изображения офлайн: если нет кэша → показать placeholder
```

---

## ПРОМПТ 8 — Обновление виджета из Flashcards

```
Добавь обновление виджета рабочего стола после сессии Flashcards.

### Задача:

После каждого завершения сессии Flashcards (FlashcardSessionComplete) и после каждого ответа "Знаю" (новое слово изучено):

1. Обновить данные виджета через home_widget:
   - Текущее слово: следующее слово на повторение или случайное из изученных
   - Прогресс дня: "{изучено} из {daily_goal} слов"
   - Если цель выполнена: показать "✅ Цель выполнена!"

Файл: lib/domain/usecases/update_home_widget.dart

Класс UpdateHomeWidget:
  Зависимости: ProgressRepository, SettingsRepository

  Метод: Future<void> call()
    1. Получить daily_goal и todayLearnedCount
    2. Выбрать слово для виджета:
       - Если есть слова на повторение → первое из очереди
       - Иначе → случайное из уровня пользователя
    3. Сохранить через HomeWidget.saveWidgetData:
       - 'widget_word' → слово
       - 'widget_transcription' → транскрипция
       - 'widget_translation' → перевод
       - 'widget_progress' → "3 из 5"
       - 'widget_goal_reached' → true/false
    4. HomeWidget.updateWidget(name: 'WordUpWidget')

Вызывать UpdateHomeWidget:
- В FlashcardBloc при emit FlashcardSessionComplete
- В FlashcardBloc при FlashcardAnswer(isCorrect: true) для нового слова
```

---

## ПРОМПТ 9 — Гостевой режим в Flashcards

```
Реализуй гостевой режим для модуля Flashcards.

### Поведение:

1. Определение режима:
   - Проверять через AuthRepository.isGuest (bool)
   - Гость = нет user_id в Supabase Auth

2. Flashcards для гостя работают так же, но:
   - Все данные только в Hive (слова загружены при первом запуске или из assets)
   - Прогресс SM-2 хранится в Hive box 'guest_progress'
   - Нет синхронизации, нет pending_sync
   - Streak считается только локально

3. Мягкие промпты регистрации (НЕ блокирующие):

   Файл: lib/presentation/widgets/auth/soft_auth_prompt.dart

   Показывать BottomSheet после:
   - Первой завершённой сессии: "Создай аккаунт, чтобы сохранить прогресс"
   - Каждой 5-й сессии: "Твой прогресс хранится только на этом устройстве"
   - При нажатии "Избранное": "Войди, чтобы сохранять слова в избранное"

   BottomSheet содержит:
   - Иконка + текст (1-2 строки)
   - Кнопка "Создать аккаунт" (primary)
   - Кнопка "Позже" (text button, закрывает sheet)
   - Не показывать чаще 1 раза за сессию приложения

4. Миграция при регистрации:
   Файл: lib/domain/usecases/migrate_guest_progress.dart

   Класс MigrateGuestProgress:
   Метод: Future<void> call(String newUserId)
     1. Прочитать все записи из Hive 'guest_progress'
     2. Для каждой записи → INSERT в Supabase user_word_progress
     3. Если конфликт (слово уже есть в Supabase) → взять лучший результат
     4. Очистить Hive 'guest_progress' после успешной миграции
     5. Показать SnackBar: "Прогресс перенесён в аккаунт!"
```

---

## ПРОМПТ 10 — Тесты

```
Напиши тесты для модуля Flashcards.

### Unit тесты:

test/domain/usecases/calculate_sm2_test.dart (если не создан ранее):
- Тест каждого сценария SM-2 (см. промпт 2)

test/domain/usecases/build_flashcard_queue_test.dart:
- Очередь daily: сначала повторение, потом новые
- Очередь daily: не больше daily_goal новых слов
- Очередь daily: если сегодня уже учил 3 из 5 → только 2 новых
- Очередь reviewOnly: только слова с next_review_at <= now
- Очередь favorites: только избранные, перемешанные
- Пустая очередь: вернуть пустую сессию

test/data/repositories/flashcard_repository_impl_test.dart:
- Авторизованный: данные из Supabase, кэш в Hive
- Авторизованный без сети: fallback на Hive
- Гостевой: только Hive, без вызовов Supabase
- Сохранение прогресса: проверить UPSERT

### Widget тесты:

test/presentation/widgets/flashcard_card_test.dart:
- Лицевая сторона показывает слово, транскрипцию, кнопку аудио
- Нажатие "Показать ответ" → обратная сторона с переводом
- Нажатие "Знаю" → вызывает FlashcardAnswer(isCorrect: true)
- Нажатие "Не знаю" → вызывает FlashcardAnswer(isCorrect: false)

test/presentation/blocs/flashcard_bloc_test.dart:
- StartSession → Loading → Active (с первым словом)
- Answer correct → следующее слово
- Answer incorrect → слово добавлено в конец
- Все слова пройдены → SessionComplete
- Undo → возврат к предыдущему слову
- ResumeSession → восстановление из Hive

Используй:
- mocktail для моков
- bloc_test для тестов BLoC
- flutter_test для widget тестов
```

---

## Порядок выполнения

| Шаг | Промпт               | Что получишь                  |
| --- | -------------------- | ----------------------------- |
| 0   | Контекст проекта     | Агент понимает архитектуру    |
| 1   | Сущности и модели    | Фундамент данных              |
| 2   | SM-2 алгоритм        | Ядро интервального повторения |
| 3   | Формирование очереди | Бизнес-логика сессии          |
| 4   | Репозитории          | Supabase + Hive + гость       |
| 5   | BLoC                 | Управление состоянием         |
| 6   | UI                   | Экраны и анимации             |
| 7   | Офлайн               | Кэш, синхронизация            |
| 8   | Виджет               | Обновление виджета            |
| 9   | Гостевой режим       | Работа без аккаунта           |
| 10  | Тесты                | Проверка всего модуля         |

> **Совет:** после каждого промпта проверяй `flutter analyze` и `flutter test`. Если есть ошибки — скажи агенту: "Исправь ошибки из flutter analyze".
