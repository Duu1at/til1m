# Til1m — Архитектура

**Til1m** — Flutter-приложение для изучения английских слов (перевод: RU, KY). Алгоритм интервального повторения SM-2.
**Платформы:** Android, iOS | **Версия:** v0.2

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
| Аудио             | just_audio                  | ^0.10.5 |
| Уведомления       | flutter_local_notifications | ^21.0.0 |
| Домашний виджет   | home_widget                 | ^0.9.0  |
| Локализация       | easy_localization           | ^3.0.8  |
| Сериализация      | json_serializable           | ^6.9.4  |
| Кодогенерация     | build_runner                | ^2.4.15 |
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
│   │   ├── word.dart                # Word, WordTranslation, WordExample
│   │   ├── user_progress.dart       # UserWordProgress (SM-2)
│   │   └── user_settings.dart       # UserSettings
│   ├── repositories/                # abstract interface классы
│   │   ├── word_repository.dart
│   │   ├── auth_repository.dart
│   │   └── progress_repository.dart
│   └── usecases/
│       └── apply_sm2_result.dart
│
├── data/
│   ├── datasources/
│   │   ├── local/                   # Hive
│   │   └── remote/                  # Supabase
│   ├── models/                      # JSON-сериализуемые модели
│   └── repositories/
│       └── auth_repository_impl.dart
│
├── presentation/
│   ├── screens/
│   │   ├── language_select/
│   │   │   └── language_select_screen.dart   # Выбор языка интерфейса (первый экран)
│   │   ├── onboarding/
│   │   │   ├── welcome_screen.dart
│   │   │   └── onboarding_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── home/home_screen.dart
│   │   ├── flashcards/flashcards_screen.dart
│   │   ├── spelling/spelling_screen.dart
│   │   ├── dictionary/dictionary_screen.dart
│   │   ├── favorites/favorites_screen.dart
│   │   ├── profile/profile_screen.dart
│   │   ├── statistics/statistics_screen.dart
│   │   ├── settings/settings_screen.dart
│   │   └── word_detail/word_detail_screen.dart
│   ├── blocs/
│   │   ├── auth/
│   │   │   ├── auth_cubit.dart
│   │   │   └── auth_state.dart
│   │   ├── settings/
│   │   │   ├── settings_cubit.dart
│   │   │   └── settings_state.dart
│   │   └── statistics/
│   │       ├── statistics_cubit.dart
│   │       └── statistics_state.dart
│   └── widgets/
│       ├── auth/          # auth_email_field, auth_password_field, auth_social_button, auth_or_divider
│       ├── onboarding/    # goal_step, level_step, time_step, progress_bar, next_button, level_card, goal_option, time_picker_card, welcome_feature_row
│       ├── profile/       # avatar, avatar_section, level_badge, menu_card, menu_item, stat_cell, quick_stats_row, logout_button, guest_call_to_action
│       ├── settings/      # goal_tile, level_tile, language_tile, theme_tile, reminder_tile, account_tile, section_header
│       └── statistics/    # stat_card, top_stats_row, progress_card, level_progress_row, guest_banner
│
├── services/
│   ├── audio/
│   ├── notifications/
│   ├── sync/
│   └── widget_service/
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
| `core/`         | Router, Theme, Constants, Errors           | Flutter SDK             |
| `services/`     | Audio, Notifications, Sync, Widget         | domain + внешние пакеты |

---

## Ключевые сущности

```dart
class Word extends Equatable {
  final String id;
  final String word;
  final WordLevel level;           // a1, a2, b1, b2, c1, c2
  final String? transcriptionText;
  final String? audioUrl;
  final String? imageUrl;
  final String? partOfSpeech;
  final List<WordTranslation> translations;  // ru / ky / en
  final List<WordExample> examples;
}

class UserWordProgress extends Equatable {
  final String wordId;
  final String userId;
  final double easeFactor;       // min 1.3
  final int repetitions;
  final DateTime nextReviewAt;
  final WordStatus status;       // new / learning / known
}

class UserSettings extends Equatable {
  final int dailyGoal;           // 3, 5, 10 или кастомное
  final WordLevel englishLevel;
  final String uiLanguage;       // 'ru', 'ky', 'en'
  final TimeOfDay? reminderTime;
  final AppThemeMode theme;      // light / dark / system
}
```

---

## State Management

- **Cubit** — простые переходы: Auth, Settings, Statistics, Onboarding
- **BLoC** — сложная логика с событиями: Flashcards, Dictionary (планируется)

```
Widget → BLoC.add(Event) → UseCase → Repository → DataSource
                                                        ↓
Widget ← rebuild      ← BLoC.emit(State) ←────────────
```

Структура файлов Cubit:

```
blocs/auth/
├── auth_cubit.dart
└── auth_state.dart    # sealed class
```

Состояния `AuthCubit`:

| Состояние                   | Описание                                    |
| --------------------------- | ------------------------------------------- |
| `AuthInitial`               | Начальное, идёт проверка сессии             |
| `AuthLoading`               | Выполняется запрос к Supabase               |
| `AuthAuthenticated`         | Пользователь вошёл                         |
| `AuthUnauthenticated`       | Нет сессии                                  |
| `AuthGuest`                 | Гостевой режим                              |
| `AuthPasswordResetSent`     | Письмо для сброса пароля отправлено         |
| `AuthEmailConfirmationSent` | Письмо подтверждения отправлено (+ email)   |
| `AuthError`                 | Ошибка авторизации (+ message)              |

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
| `/flashcards`       | FlashcardsScreen       | ShellRoute          |
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

| Box             | Содержит                                   |
| --------------- | ------------------------------------------ |
| `words_box`     | Кэш слов из Supabase                       |
| `progress_box`  | Прогресс (для гостей — основное хранилище) |
| `settings_box`  | Настройки пользователя                     |
| `favorites_box` | Избранные (только для гостей)              |

**SharedPreferences** — примитивы и флаги:

- `guest_mode`, `first_launch`, `selected_level`, `daily_goal`, `study_start_time`

---

## SM-2 алгоритм

Файл: `lib/domain/usecases/apply_sm2_result.dart`

```
Знаю:
  repetitions += 1
  easeFactor = max(1.3, easeFactor + 0.1)
  nextReviewAt = now + interval
  if interval >= 21d → status = 'known'

Не знаю:
  repetitions = 0
  easeFactor = max(1.3, easeFactor - 0.2)
  nextReviewAt = now + 1h
  status = 'learning'
```

| Повторение | Интервал                  |
| ---------- | ------------------------- |
| 1-е        | 1 день                    |
| 2-е        | 6 дней                    |
| 3-е+       | `предыдущий × easeFactor` |

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

|                 |                                         |
| --------------- | --------------------------------------- |
| Primary         | `#4F46E5` (Indigo)                      |
| Background dark | `#0F172A`                               |
| Surface dark    | `#1E293B`                               |
| Шрифт           | Inter (Regular, Medium, SemiBold, Bold) |

Цвета уровней: A1 Green · A2 Lime · B1 Amber · B2 Red · C1 Purple · C2 Sky

---

## Гостевой режим

1. Нажать «Продолжить как гость» → `guest_mode = true` в SharedPreferences
2. Прогресс хранится в Hive, Supabase не используется
3. При регистрации: `AuthRepository.migrateGuestProgress()` → переносит данные из Hive в Supabase

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
                                         └─ [Offline] LocalDataSource (Hive)
                                                ↓
                              BLoC.emit(State) → Screen rebuild
```

---

## Роадмап

| Версия       | Задачи                                                                                |
| ------------ | ------------------------------------------------------------------------------------- |
| ~~**v0.1**~~ | ~~Welcome, Onboarding, навигация, Supabase подключение~~ ✓                            |
| **v0.2**     | Auth (email + Google + гость), Settings/Statistics BLoC, роутинг с redirect-логикой ✓ |
| v0.3         | WordRepository, карточка слова, аудио, изображения                                    |
| v0.4         | Flashcards + SM-2, Spelling                                                           |
| v0.5         | Home Widget, Push-уведомления                                                         |
| v0.6         | Статистика, Streak, прогресс по уровням                                               |
| v1.0         | Тестирование, публикация                                                              |
