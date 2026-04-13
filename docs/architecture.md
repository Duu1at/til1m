# Til1m — Архитектура

**Til1m** — Flutter-приложение для изучения английских слов (перевод: RU, KY). Алгоритм интервального повторения SM-2.
**Платформы:** Android, iOS | **Версия:** v0.3

---

## Стек

| Категория         | Технология                  | Версия  |
| ----------------- | --------------------------- | ------- |
| UI                | Flutter                     | ^3.11.1 |
| State Management  | flutter_bloc                | ^9.1.1  |
| Навигация         | go_router                   | ^17.1.0 |
| Backend           | supabase_flutter            | ^2.9.1  |
| Локальный кэш     | hive_flutter                | ^1.1.0  |
| Простое хранилище | shared_preferences          | ^2.5.3  |
| Аудио (TTS)       | flutter_tts                 | ^4.2.5  |
| Аудио (сеть)      | just_audio                  | ^0.10.5 |
| HTTP-клиент       | dio                         | ^5.8.0+1|
| Авторизация (G)   | google_sign_in              | ^6.2.2  |
| Авторизация (A)   | sign_in_with_apple          | ^6.1.4  |
| Сеть              | connectivity_plus           | ^7.1.0  |
| Изображения       | cached_network_image        | ^3.4.1  |
| Уведомления       | flutter_local_notifications | ^21.0.0 |
| Домашний виджет   | home_widget                 | ^0.9.0  |
| Локализация       | easy_localization           | ^3.0.8  |
| DI                | get_it                      | ^9.2.1  |
| Сериализация      | json_serializable           | ^6.9.4  |
| Утилиты           | uuid, intl, crypto          | latest  |
| Кодогенерация     | build_runner                | ^2.4.15 |
| Тесты             | bloc_test, mocktail         | latest  |
| Линтинг           | very_good_analysis          | ^10.2.0 |

---

## Структура директорий

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart       # SharedPrefs ключи, Hive боксы, SM-2 дефолты
│   │   ├── locale_keys.dart         # Ключи локализации
│   │   └── supabase_constants.dart  # URL, anon key, таблицы, бакеты
│   ├── di/
│   │   └── service_locator.dart     # Dependency injection (GetIt)
│   ├── errors/
│   │   ├── app_auth_exception.dart  # Кастомные исключения авторизации
│   │   └── auth_error_mapper.dart   # Маппинг ошибок Supabase → AppAuthException
│   ├── network/
│   │   └── connectivity_service.dart  # Мониторинг сети (connectivity_plus)
│   ├── router/app_router.dart       # Все маршруты GoRouter + AppRoutes
│   ├── shell/main_shell.dart        # BottomNavigationBar
│   ├── theme/
│   │   ├── app_theme.dart           # Material3 light/dark темы
│   │   ├── app_colors.dart          # Цветовая палитра
│   │   └── app_typography.dart      # Шрифты и стили текста
│   └── utils/
│       └── go_router_refresh_stream.dart
│
├── domain/                          # Чистый Dart, без Flutter
│   ├── entities/
│   │   ├── word.dart                # Word, WordLevel, PartOfSpeech
│   │   ├── translation.dart         # WordTranslation
│   │   ├── word_example.dart        # WordExample
│   │   ├── word_progress.dart       # WordProgress (лёгкая, сессионная)
│   │   ├── user_progress.dart       # UserWordProgress (полная, синхронизируемая) + WordStatus
│   │   ├── user_settings.dart       # UserSettings
│   │   └── flashcard_session.dart   # FlashcardSession, FlashcardSessionItem
│   ├── repositories/                # abstract interface классы
│   │   ├── word_repository.dart
│   │   ├── auth_repository.dart
│   │   └── progress_repository.dart
│   └── usecases/
│       ├── calculate_sm2.dart       # CalculateSm2 → Sm2Result
│       └── prefetch_flashcard_data.dart
│
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── word_local_datasource.dart
│   │   │   ├── progress_local_datasource.dart
│   │   │   └── flashcard_local_datasource.dart   # Сохранение/восстановление сессии
│   │   ├── remote/
│   │   │   ├── word_remote_datasource.dart
│   │   │   ├── progress_remote_datasource.dart
│   │   │   └── flashcard_remote_datasource.dart
│   │   └── sync/
│   │       └── progress_sync_service.dart        # Flush офлайн-прогресса в Supabase
│   ├── models/
│   │   ├── word_model.dart
│   │   ├── word_progress_model.dart
│   │   ├── user_word_progress_model.dart
│   │   └── flashcard_session_model.dart
│   ├── repositories/
│   │   ├── auth_repository_impl.dart
│   │   ├── word_repository_impl.dart
│   │   └── flashcard_repository_impl.dart
│   └── services/
│       ├── update_home_widget.dart   # Обновляет домашний виджет
│       └── migrate_guest_progress.dart
│
├── presentation/
│   ├── screens/
│   │   ├── onboarding/
│   │   │   ├── language_select_screen.dart
│   │   │   ├── welcome_screen.dart
│   │   │   └── onboarding_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── home/home_screen.dart
│   │   ├── flashcard/flashcard_screen.dart
│   │   ├── spelling/spelling_screen.dart
│   │   ├── dictionary/dictionary_screen.dart
│   │   ├── favorites/favorites_screen.dart
│   │   ├── word_detail/word_detail_screen.dart
│   │   ├── profile/profile_screen.dart
│   │   ├── statistics/statistics_screen.dart
│   │   └── settings/settings_screen.dart
│   ├── blocs/
│   │   ├── auth/           # auth_cubit.dart, auth_state.dart
│   │   ├── home/           # home_cubit.dart, home_state.dart
│   │   ├── flashcard/      # flashcard_bloc.dart, flashcard_event.dart, flashcard_state.dart
│   │   ├── word_detail/    # word_detail_cubit.dart, word_detail_state.dart
│   │   ├── dictionary/     # dictionary_cubit.dart, dictionary_state.dart
│   │   ├── settings/       # settings_cubit.dart, settings_state.dart
│   │   └── statistics/     # statistics_cubit.dart, statistics_state.dart
│   └── widgets/
│       ├── auth/           # auth_email_field, auth_password_field, soft_auth_prompt, ...
│       ├── onboarding/     # goal_step, level_step, time_step, lang_card, ...
│       ├── flashcard/      # flashcard_card, flashcard_front_face, back_face, flashcard_result_screen, ...
│       ├── word_detail/    # word_detail_body, word_examples_section, word_know_buttons, ...
│       ├── home/           # home_header, home_stats_row
│       ├── dictionary/     # word_list_tile, dictionary_search_field, level_and_sort_row
│       ├── profile/        # avatar, menu_card, quick_stats_row, guest_call_to_action, ...
│       ├── settings/       # goal_tile, level_tile, language_tile, theme_tile, ...
│       └── statistics/     # stat_card, top_stats_row, level_progress_row, guest_banner
│
└── main.dart
```

---

## Слои Clean Architecture

```
Presentation (Screens + BLoC)
        ↓ вызывает
Domain (Entities + UseCases + Repos interface)
        ↑ реализует
Data (Repos impl + Models + DataSources)
```

| Слой            | Содержит                                   | Зависит от              |
| --------------- | ------------------------------------------ | ----------------------- |
| `domain/`       | Entities, Use Cases, Repository interfaces | Dart SDK + equatable    |
| `data/`         | Repository impl, Models, DataSources       | domain + supabase/hive  |
| `presentation/` | Screens, BLoC/Cubit, Widgets               | domain + flutter_bloc   |
| `core/`         | Router, Theme, Constants, Errors, Network  | Flutter SDK             |

---

## Ключевые сущности

```dart
// Слово из словаря
class Word extends Equatable {
  final String id;
  final String word;
  final WordLevel level;           // a1, a2, b1, b2, c1, c2
  final String? transcriptionText;
  final String? audioUrl;
  final String? imageUrl;
  final String? partOfSpeech;
  final List<WordTranslation> translations;  // ru / ky
  final List<WordExample> examples;
}

// Лёгкий прогресс — используется в сессии флэш-карточек
class WordProgress extends Equatable {
  final String wordId;
  final WordStatus status;    // newWord / learning / known
  final double easeFactor;    // default 2.5, min 1.3
  final int repetitions;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;

  bool get isDueNow => nextReviewAt == null || nextReviewAt!.isBefore(now);
}

// Полный прогресс — сохраняется в Supabase / Hive, включает userId
class UserWordProgress extends Equatable {
  final String id;        // '{userId}_{wordId}'
  final String userId;
  final String wordId;
  final WordStatus status;
  final double easeFactor;
  final int repetitions;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;
}

// Сессия флэш-карточек
class FlashcardSession extends Equatable {
  final List<FlashcardSessionItem> items;
  final int currentIndex;
  final List<String> failedWordIds;
  final DateTime sessionStartedAt;
  final int answeredCount;
  final int correctCount;

  bool get isComplete => currentIndex >= items.length;
}

class UserSettings extends Equatable {
  final int dailyGoal;
  final WordLevel englishLevel;
  final String uiLanguage;       // 'ru', 'ky', 'en'
  final TimeOfDay? reminderTime;
  final AppThemeMode theme;      // light / dark / system
}
```

---

## State Management

- **Cubit** — простые переходы: Auth, Home, WordDetail, Dictionary, Settings, Statistics
- **BLoC** — сложная логика с событиями: Flashcard

```
Widget → BLoC.add(Event) → UseCase → Repository → DataSource
                                                        ↓
Widget ← rebuild      ← BLoC.emit(State) ←────────────
```

### FlashcardBloc

Файлы: `blocs/flashcard/flashcard_bloc.dart|event.dart|state.dart`

| Событие                    | Описание                                           |
| -------------------------- | -------------------------------------------------- |
| `FlashcardStartSession`    | Начать новую сессию (source: review/newWords/mixed) |
| `FlashcardResumeSession`   | Восстановить прерванную сессию из Hive             |
| `FlashcardFlipCard`        | Перевернуть карточку (лицо/оборот)                 |
| `FlashcardAnswer`          | Ответить «знаю» / «не знаю»                        |
| `FlashcardUndo`            | Отменить последний ответ (стек до 5 шагов)         |
| `FlashcardSkip`            | Пропустить карточку без оценки                     |
| `FlashcardPlayAudio`       | Произнести слово через TTS                         |
| `FlashcardLoadMore`        | Добавить ещё 10 новых слов в очередь               |
| `FlashcardEndSession`      | Завершить сессию и показать результат              |

| Состояние                  | Описание                                          |
| -------------------------- | ------------------------------------------------- |
| `FlashcardInitial`         | Начальное                                         |
| `FlashcardLoading`         | Загрузка данных                                   |
| `FlashcardActive`          | Активная сессия (текущее слово, прогресс, флаги)  |
| `FlashcardSessionComplete` | Итоги сессии (счёт, время, dailyGoalReached)      |
| `FlashcardEmpty`           | Нет слов для данного источника                    |
| `FlashcardError`           | Ошибка загрузки                                   |

`FlashcardActive` содержит флаг `isOffline` — при потере сети прогресс буферизуется и отправляется в Supabase при восстановлении связи (`ProgressSyncService.flush`).

### AuthCubit — состояния

| Состояние                   | Описание                                  |
| --------------------------- | ----------------------------------------- |
| `AuthInitial`               | Проверка сессии                           |
| `AuthLoading`               | Запрос к Supabase                         |
| `AuthAuthenticated`         | Пользователь вошёл                        |
| `AuthUnauthenticated`       | Нет сессии                                |
| `AuthGuest`                 | Гостевой режим                            |
| `AuthPasswordResetSent`     | Письмо для сброса пароля отправлено       |
| `AuthEmailConfirmationSent` | Письмо подтверждения отправлено (+ email) |
| `AuthError`                 | Ошибка авторизации (+ message)            |

---

## SM-2 алгоритм

Файл: `lib/domain/usecases/calculate_sm2.dart`  
Класс: `CalculateSm2` → возвращает `Sm2Result(updatedProgress, interval, returnToQueue)`

```
Знаю (isCorrect = true):
  repetitions += 1
  interval:  rep=1→1d, rep=2→6d, rep≥3→prevInterval × easeFactor
  easeFactor += 0.0  (при quality=4)
  nextReviewAt = now + interval (days)
  status = repetitions >= 3 ? 'known' : 'learning'
  returnToQueue = false

Не знаю (isCorrect = false):
  repetitions = 0
  easeFactor -= 0.2  (min 1.3)
  nextReviewAt = now  (карточка возвращается в очередь немедленно)
  status = 'learning'
  returnToQueue = true  (слово добавляется в конец сессии, max 3 раза)
```

| Повторение | Интервал                  |
| ---------- | ------------------------- |
| 1-е        | 1 день                    |
| 2-е        | 6 дней                    |
| 3-е+       | `предыдущий × easeFactor` |

---

## Навигация (GoRouter)

Все маршруты в `lib/core/router/app_router.dart`. Начальный экран: `/language-select`.

| Путь                | Экран                  | Тип                 |
| ------------------- | ---------------------- | ------------------- |
| `/language-select`  | LanguageSelectScreen   | GoRoute (начальный) |
| `/welcome`          | WelcomeScreen          | GoRoute             |
| `/onboarding`       | OnboardingScreen       | GoRoute             |
| `/login`            | LoginScreen            | GoRoute             |
| `/register`         | RegisterScreen         | GoRoute             |
| `/forgot-password`  | ForgotPasswordScreen   | GoRoute             |
| `/home`             | HomeScreen             | ShellRoute          |
| `/flashcards`       | FlashcardScreen        | ShellRoute          |
| `/spelling`         | SpellingScreen         | ShellRoute          |
| `/dictionary`       | DictionaryScreen       | ShellRoute          |
| `/favorites`        | FavoritesScreen        | ShellRoute          |
| `/profile`          | ProfileScreen          | ShellRoute          |
| `/statistics`       | StatisticsScreen       | ShellRoute          |
| `/settings`         | SettingsScreen         | ShellRoute          |
| `/word/:id`         | WordDetailScreen       | GoRoute (вне shell) |

**Redirect-логика:**
- Неаутентифицированный пользователь (не гость) → `/login` при переходе на защищённые роуты
- Аутентифицированный пользователь → `/home` при попытке открыть `/login` или `/register`
- Гостевой режим (`AuthGuest`) даёт доступ к защищённым роутам

**BottomNav (ShellRoute):** Главная · Учиться · Словарь · Профиль

---

## База данных (Supabase)

Схема: `supabase/schema.sql`. RLS включён везде.

| Таблица              | Описание                      | Доступ           |
| -------------------- | ----------------------------- | ---------------- |
| `words`              | Справочник слов               | Публичный SELECT |
| `word_translations`  | Переводы ru/ky                | Публичный SELECT |
| `word_examples`      | Примеры предложений           | Публичный SELECT |
| `user_settings`      | Настройки (1 запись на юзера) | Только свои      |
| `user_word_progress` | SM-2 прогресс                 | Только свои      |
| `user_favorites`     | Избранные слова               | Только свои      |

`user_settings` создаётся автоматически через DB trigger при регистрации.

---

## Локальное хранилище

**Hive** — коллекции и кэш:

| Box             | Содержит                                        |
| --------------- | ----------------------------------------------- |
| `words_box`     | Кэш слов из Supabase                            |
| `progress_box`  | Прогресс (для гостей — основное хранилище)      |
| `settings_box`  | Настройки пользователя                          |
| `favorites_box` | Избранные (только для гостей)                   |
| `session_box`   | Сохранённая незавершённая сессия флэш-карточек  |

**SharedPreferences** — примитивы и флаги:

- `guest_mode`, `first_launch`, `selected_level`, `daily_goal`, `study_start_time`

---

## Оффлайн-синхронизация

`ProgressSyncService` (`data/datasources/sync/progress_sync_service.dart`):

1. Прогресс всегда сначала пишется в Hive.
2. `ConnectivityService` (`core/network/`) следит за состоянием сети.
3. При появлении сети `FlashcardBloc` вызывает `flush(userId)` — все буферизованные записи отправляются в `user_word_progress` Supabase.
4. Результат `SyncOutcome`: `success | partialSuccess | error | noData`.

---

## Локализация

- Языки: `en`, `ru` (fallback), `ky`
- Файлы: `assets/translations/{en,ru,ky}.json`
- Ключи: `camelCase`. Плейсхолдеры: `{val}` / `{value}`

```dart
EasyLocalization(
  supportedLocales: [Locale('en'), Locale('ru'), Locale('ky')],
  path: 'assets/translations',
  fallbackLocale: Locale('ru'),
  child: MyApp(),
)

Text(LocaleKeys.welcomeTitle.tr(context: context))
```

---

## Тема и стили

Material3, light/dark. Цвета и типографика вынесены в отдельные файлы:

- `lib/core/theme/app_theme.dart` — сборка ThemeData
- `lib/core/theme/app_colors.dart` — цветовая палитра
- `lib/core/theme/app_typography.dart` — шрифты и стили текста

|                 |                                                    |
| --------------- | -------------------------------------------------- |
| Primary         | `#4F46E5` (Indigo)                                 |
| Background dark | `#0F172A`                                          |
| Surface dark    | `#1E293B`                                          |
| Шрифт           | NotoSans (Regular, Medium 500, SemiBold 600, Bold 700) |

Цвета уровней: A1 Green · A2 Lime · B1 Amber · B2 Red · C1 Purple · C2 Sky

---

## Гостевой режим

1. Нажать «Продолжить как гость» → `guest_mode = true` в SharedPreferences
2. Прогресс хранится в Hive, Supabase не используется
3. При регистрации: `MigrateGuestProgress` (`data/services/`) → переносит данные из Hive в Supabase

---

## Конфигурация

Credentials через `--dart-define`, не в коде:

```bash
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Скрипты: `run.sh`, `run_dev.sh`, `run_prod.sh`. Файлы `.env*` в `.gitignore`.

---

## Поток данных

```
Screen → BLoC.add(Event) → UseCase → Repository
                                         ├─ [Online]  RemoteDataSource (Supabase) → кэш в Hive
                                         └─ [Offline] LocalDataSource (Hive) → SyncService при reconnect
                                                ↓
                              BLoC.emit(State) → Screen rebuild
```

---

## Роадмап

| Версия       | Задачи                                                                                 |
| ------------ | -------------------------------------------------------------------------------------- |
| ~~**v0.1**~~ | ~~Welcome, Onboarding, навигация, Supabase подключение~~ ✓                             |
| ~~**v0.2**~~ | ~~Auth (email + Google + гость), Settings/Statistics BLoC, роутинг с redirect-логикой~~ ✓ |
| ~~**v0.3**~~ | ~~WordRepository, карточка слова, Flashcards + SM-2, TTS, оффлайн-синхронизация~~ ✓   |
| **v0.4**     | Home Widget, Push-уведомления                                                          |
| v0.5         | Spelling (все уровни)                                                                  |
| v0.6         | Статистика, Streak, прогресс по уровням                                                |
| v1.0         | Тестирование, публикация                                                               |
