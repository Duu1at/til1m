# WordUp

Мобильное приложение для изучения английских слов с переводом на русский и кыргызский языки.
Использует алгоритм интервального повторения **SM-2**.

**Платформы:** Android, iOS

---

## Стек

- **Flutter** + **Dart**
- **Supabase** — база данных, авторизация, хранилище
- **flutter_bloc** — state management (BLoC / Cubit)
- **go_router** — навигация
- **Hive** — локальный кэш (offline-режим)
- **easy_localization** — мультиязычность (EN, RU, KY)
- **just_audio** — аудио-произношения
- **flutter_local_notifications** — напоминания
- **home_widget** — виджет рабочего стола

---

## Быстрый старт

```bash
# Зависимости
flutter pub get

# Запуск
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...

# Или через скрипты
./run_dev.sh
./run_prod.sh
```

---

## Сборка

```bash
# Android
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...

# iOS
flutter build ipa --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

---

## Кодогенерация

```bash
# После изменений @JsonSerializable / @HiveType / @freezed
dart run build_runner build --delete-conflicting-outputs

# После изменений в JSON-переводах
dart run easy_localization:generate
```

---

## Структура проекта

```
lib/
├── core/          # Роутер, тема, константы, ошибки
├── domain/        # Entities, Use Cases, Repository interfaces
├── data/          # Repository impl, Models, DataSources (Supabase + Hive)
├── presentation/  # Screens, BLoC/Cubit, Widgets
└── services/      # Audio, Notifications, Sync, HomeWidget
```

Подробнее: [`docs/architecture.md`](docs/architecture.md)

---

## Проверка и тесты

```bash
flutter analyze
flutter test
```

---

## Документация

| Файл | Описание |
|---|---|
| [`docs/architecture.md`](docs/architecture.md) | Архитектура, слои, БД, SM-2, навигация |
| [`docs/code_rules.md`](docs/code_rules.md) | Правила кода, именование, best practices |
| [`CLAUDE.md`](CLAUDE.md) | Инструкции для AI-ассистента |

---

## Роадмап

| Версия | Статус | Задачи |
|---|---|---|
| **v0.1** | В процессе | Onboarding, навигация, Supabase |
| v0.2 | | Карточка слова, аудио, изображения |
| v0.3 | | Flashcards + SM-2, Spelling |
| v0.4 | | Home Widget, Push-уведомления |
| v0.5 | | Auth (email + Google), синхронизация |
| v0.6 | | Статистика, Streak |
| v1.0 | | Публикация |
