# Til1m — Flutter App (Claude Code Workflow)

## Проект

Мобильное приложение для изучения английских слов с переводом на русский и кыргызский языки.

- **Платформа:** Flutter (Android + iOS)
- **Backend:** Supabase (PostgreSQL + Auth + Storage)
- **State management:** BLoC / Cubit (`flutter_bloc`)
- **Навигация:** `go_router`
- **Локальный кэш:** Hive
- **Аудио:** `just_audio`
- **Виджет:** `home_widget`
- **Уведомления:** `flutter_local_notifications`

---

## Архитектура

Проект использует **Clean Architecture** с разделением на слои:

```
lib/
├── core/                  # Утилиты, темы, роутер, константы
│   ├── constants/         # AppConstants, SupabaseConstants
│   ├── theme/             # AppTheme (light/dark)
│   ├── router/            # GoRouter (AppRoutes)
│   ├── shell/             # MainShell (BottomNavigationBar)
│   ├── utils/
│   └── errors/
├── data/                  # Реализация репозиториев, модели
│   ├── datasources/
│   │   ├── local/         # Hive datasources
│   │   └── remote/        # Supabase datasources
│   ├── models/            # Data models (JSON serializable)
│   └── repositories/      # Реализации (implements domain)
├── domain/                # Бизнес-логика (чистая, без зависимостей)
│   ├── entities/          # Word, UserWordProgress, UserSettings
│   ├── repositories/      # Abstract repositories
│   └── usecases/          # ApplySm2Result и другие
├── presentation/          # UI слой
│   ├── screens/           # Экраны по фичам
│   ├── widgets/           # Переиспользуемые виджеты
│   └── blocs/             # BLoC / Cubit по фичам
└── services/              # Audio, Notifications, Widget, Sync
```

---

## Ключевые сущности

### Word (domain/entities/word.dart)

- `id`, `word`, `transcriptionText`, `audioUrl`, `imageUrl`
- `level` (WordLevel: a1–c2), `partOfSpeech`
- `translations` → List<WordTranslation> (ru/ky)
- `examples` → List<WordExample>

### UserWordProgress (domain/entities/user_progress.dart)

- SM-2 поля: `easeFactor`, `repetitions`, `nextReviewAt`, `lastReviewedAt`
- `status`: new / learning / known

### UserSettings (domain/entities/user_settings.dart)

- `dailyGoal`, `englishLevel`, `uiLanguage`, `reminderTime`, `theme`

---

## SM-2 алгоритм

Логика в `domain/usecases/apply_sm2_result.dart`:

- **"Знаю"** → repetitions++, interval × easeFactor, следующее повторение через N дней
- **"Не знаю"** → repetitions=0, следующее повторение через ~1 час
- `known` статус при interval >= 21 день
- `easeFactor` min = 1.3

---

## База данных (Supabase)

Схема: `supabase/schema.sql`

Таблицы:

- `words` — слова
- `word_translations` — переводы (ru/ky)
- `word_examples` — примеры предложений
- `user_settings` — настройки пользователя (auto-created on register)
- `user_word_progress` — прогресс по SM-2
- `user_favorites` — избранные слова

RLS включён. Пользователь видит только свои данные. Слова — публичные.

---

## Конфигурация Supabase

Credentials передаются через `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Или через `.env` + `flutter_dotenv` (добавить по желанию).

---

## Навигация (GoRouter)

Роуты в `core/router/app_router.dart`:

- `/welcome` — Welcome Screen (только при первом запуске)
- `/onboarding` — Онбординг (4 шага)
- `/login`, `/register` — Авторизация
- `/home` — Главный экран (shell)
- `/flashcards`, `/spelling` — Режимы обучения (shell)
- `/dictionary`, `/favorites` — Словарь (shell)
- `/profile`, `/statistics`, `/settings` — Профиль (shell)
- `/word/:id` — Карточка слова (вне shell)

Shell (MainShell) отображает нижнюю навигацию с 4 вкладками.

---

## Гостевой режим

- Прогресс хранится в Hive локально
- Нет синхронизации и избранного
- При регистрации — `AuthRepository.migrateGuestProgress()` переносит данные
- `SharedPreferences` key: `guest_mode`

---

## Правила разработки

### Общие

- Всегда следовать Clean Architecture: UI → BLoC → UseCase → Repository → DataSource
- BLoC для сложной логики, Cubit для простого состояния
- Не писать бизнес-логику в виджетах
- Dart null-safety обязателен везде

### Именование

- Файлы: `snake_case.dart`
- Классы: `PascalCase`
- BLoC: `FeatureBloc`, `FeatureCubit`, `FeatureState`, `FeatureEvent`
- Репозитории: `abstract WordRepository` в domain, `WordRepositoryImpl` в data

### Supabase

- Все запросы через RLS — никогда не передавать service key в приложение
- Использовать `supabase.auth.currentUser` для получения userId
- Офлайн-fallback: если нет сети, брать из Hive

### Стиль кода

- Использовать `freezed` для моделей данных где нужна иммутабельность
- `equatable` для сравнения entities
- Константы только в `AppConstants` или `SupabaseConstants`

---

## Приоритеты (Roadmap)

| Версия | Что делать                                           |
| ------ | ---------------------------------------------------- |
| v0.1   | Welcome, Onboarding, навигация, Supabase подключение |
| v0.2   | WordRepository, карточка слова, аудио, изображения   |
| v0.3   | Flashcards + SM-2, Spelling все уровни               |
| v0.4   | Home Widget, Push-уведомления                        |
| v0.5   | Auth (email + Google), синхронизация прогресса гостя |
| v0.6   | Статистика, Streak, прогресс по уровням              |
| v1.0   | Тестирование, публикация                             |

**Текущая цель: v0.1** — скелет готов, нужно реализовать полноценный онбординг и подключить Supabase.

---

## Запуск

```bash
# Установить зависимости
flutter pub get

# Запуск (dev)
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# Сборка Android
flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# Сборка iOS
flutter build ipa --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

---

## Частые команды

```bash
# Генерация кода (freezed, json_serializable, injectable)
dart run build_runner build --delete-conflicting-outputs

# Проверка кода
flutter analyze

# Тесты
flutter test

# Обновить виджет рабочего стола (Android)
# Вызывается через HomeWidget.updateWidget(name: 'Til1mWidget')
```

---

## Что НЕ входит в MVP (v1.0)

- Распознавание речи
- Мини-игры (matching, crossword)
- Пользовательские карточки
- Рейтинги / соревнования
- Web-версия
- Платный функционал
