# WordUp — Code Rules

## Общие правила

- **Linter:** `very_good_analysis` v10.2.0
- **Длина строки:** 120 символов → `dart format . --line-length 120`
- **Trailing commas:** preserve
- Зависимости только внутрь: `Presentation → Domain ← Data`
- Один класс — одно дело. Без `dynamic`. Без `print`.

---

## Dart модификаторы классов

| Модификатор                | Где                    | Зачем                                              |
| -------------------------- | ---------------------- | -------------------------------------------------- |
| `abstract interface class` | Repository в domain    | Только `implements`, не `extends`                  |
| `sealed class`             | BLoC Events, States    | Exhaustive switch — компилятор проверяет все ветки |
| `final class`              | Конкретные Event/State | Запрет наследования от конкретного состояния       |
| `final` (поле/переменная)  | Везде по умолчанию     | Иммутабельность, явное намерение                   |

```dart
// Repository interface
abstract interface class WordRepository {
  Future<List<Word>> getWordsForReview({required String userId});
}

// States
sealed class WordsState extends Equatable { const WordsState(); }

final class WordsInitial extends WordsState {
  const WordsInitial();
  @override List<Object> get props => [];
}
final class WordsLoading extends WordsState {
  const WordsLoading();
  @override List<Object> get props => [];
}
final class WordsLoaded extends WordsState {
  const WordsLoaded(this.words);
  final List<Word> words;
  @override List<Object> get props => [words];
}
final class WordsError extends WordsState {
  const WordsError(this.message);
  final String message;
  @override List<Object> get props => [message];
}
```

```dart
// ✅ final везде
final words = await _repository.getWords();
final class WordCard extends StatelessWidget {
  final Word word; // final поле
}

// ❌
var words = await _repository.getWords();
class WordCard { Word word; } // мутабельное поле
```

---

## Именование

| Что               | Стиль                 | Пример                                     |
| ----------------- | --------------------- | ------------------------------------------ |
| Файлы             | `snake_case`          | `word_repository.dart`                     |
| Классы            | `PascalCase`          | `WordRepositoryImpl`                       |
| BLoC события      | Noun + Past/Requested | `WordLoadRequested`, `AuthLogoutRequested` |
| Переменные/методы | `camelCase`           | `wordsForReview`, `getWordsByLevel`        |
| Приватные         | `_prefix`             | `_repository`, `_onWordLoadRequested`      |

```dart
// ❌ Императив в событиях
final class LoadWords extends WordsEvent {}

// ✅
final class WordLoadRequested extends WordsEvent {}
```

---

## Структура файлов

### Один виджет — один файл

```dart
// ❌ Widget-метод
Widget _buildHeader() => Text('...');

// ✅ Отдельный файл presentation/widgets/word_card/word_card.dart
class WordCard extends StatelessWidget {
  const WordCard({super.key, required this.word});
  final Word word;
  @override Widget build(BuildContext context) { ... }
}
```

- Экран — не более **~180 строк**. Если больше — выноси поля/логику в отдельные виджеты
- Shared `typedef` → `core/utils/types.dart`

### Порядок членов класса

```
1. static const поля
2. final зависимости
3. Конструктор + регистрация on<>
4. Публичные методы
5. Приватные обработчики
```

---

## Clean Architecture — импорты

| Слой            | Может импортировать                    |
| --------------- | -------------------------------------- |
| `domain/`       | Dart SDK + `equatable`                 |
| `data/`         | `domain/` + supabase, hive, dio        |
| `presentation/` | `domain/` + flutter_bloc + Flutter     |
| `core/`         | Dart SDK + Flutter (без бизнес-логики) |

```dart
// ❌
import 'package:wordup/data/models/word_model.dart'; // в domain/
import 'package:flutter/material.dart';              // в domain/entities/

// ✅
import 'package:wordup/domain/entities/word.dart';   // в presentation/
```

---

## Domain Layer

```dart
// Entity — @immutable + Equatable + все поля final
@immutable
class Word extends Equatable {
  const Word({required this.id, required this.word, required this.level, ...});
  final String id;
  final String word;
  final WordLevel level;
  @override List<Object?> get props => [id, word, level];
  Word copyWith({String? word}) => Word(id: id, word: word ?? this.word, level: level, ...);
}

// Use Case — один класс, один call
class GetWordsForReview {
  const GetWordsForReview(this._repository);
  final WordRepository _repository;
  Future<List<Word>> call({required String userId}) =>
      _repository.getWordsForReview(userId: userId);
}
```

---

## Data Layer

```dart
// Model = Entity + JSON
class WordModel extends Word {
  factory WordModel.fromJson(Map<String, dynamic> json) => WordModel(
        id: json['id'] as String,
        word: json['word'] as String,
        level: WordLevel.values.byName(json['level'] as String),
      );
  Map<String, dynamic> toJson() => {'id': id, 'word': word, 'level': level.name};
}

// Repository — offline-first
@override
Future<List<Word>> getWordsForReview({required String userId}) async {
  try {
    final words = await remoteDataSource.fetchDueWords(userId: userId);
    await localDataSource.cacheWords(words);
    return words;
  } catch (_) {
    return localDataSource.getDueWords(userId: userId);
  }
}
```

---

## Presentation Layer

```dart
// Экран — только BlocProvider + View
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => WordsBloc(
          getWordsForReview: context.read<GetWordsForReview>(),
        )..add(const WordLoadRequested()),
        child: const _HomeView(),
      );
}

// View — только switch по state
class _HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: BlocBuilder<WordsBloc, WordsState>(
          builder: (context, state) => switch (state) {
            WordsLoading()              => const _LoadingView(),
            WordsLoaded(:final words)   => _WordList(words: words),
            WordsError(:final message)  => _ErrorView(message: message),
            WordsInitial()              => const SizedBox.shrink(),
          },
        ),
      );
}
```

---

## State Management

### Cubit vs BLoC

| Cubit                          | BLoC                              |
| ------------------------------ | --------------------------------- |
| Простые переходы, тоглы, формы | Несколько событий, сложная логика |
| Settings, Theme, Onboarding    | Auth, Flashcards, Dictionary      |

### Events

```dart
sealed class WordsEvent extends Equatable { const WordsEvent(); }

final class WordLoadRequested extends WordsEvent {
  const WordLoadRequested();
  @override List<Object> get props => [];
}
```

### BLoC handler

```dart
Future<void> _onWordLoadRequested(WordLoadRequested event, Emitter<WordsState> emit) async {
  emit(const WordsLoading());
  try {
    emit(WordsLoaded(await _getWordsForReview(userId: _userId)));
  } on NetworkException catch (e) {
    emit(WordsError(e.message));
  } catch (e) {
    emit(WordsError(e.toString()));
  }
}

// Для стримов — не emit после close
await emit.forEach(_repository.watchWords(), onData: WordsLoaded.new);
```

---

## Виджеты и UI

### StatelessWidget по умолчанию

`StatefulWidget` — только для `AnimationController`, `TextEditingController`, `FocusNode`.

### Вместо Container

```dart
// ❌
Container(height: 24, color: Colors.white)

// ✅
ColoredBox(color: theme.colorScheme.surface, child: SizedBox(height: 24))
```

| Нужно        | Используй      |
| ------------ | -------------- |
| Цвет         | `ColoredBox`   |
| Размер       | `SizedBox`     |
| Декорация    | `DecoratedBox` |
| Отступ       | `Padding`      |
| Выравнивание | `Align`        |

### Цвета — только из темы

```dart
// ❌
color: Colors.white
color: Color(0xFF4F46E5)

// ✅
color: Theme.of(context).colorScheme.primary
```

### Отступы — только из AppConstants

```dart
// ❌
SizedBox(height: 24)

// ✅
SizedBox(height: AppConstants.paddingL)
```

### const везде где возможно

```dart
const SizedBox(height: 16),
const Divider(),
```

---

## Навигация

```dart
// ✅
context.go(AppRoutes.home);
context.push('/word/${word.id}');

// ❌
Navigator.of(context).push(...);
context.go('/home'); // строки напрямую
```

Логика редиректов — в `redirect` callback GoRouter, не в виджетах.

---

## Supabase

- Только **anon key** в клиенте — никогда service key
- **RLS** фильтрует на сервере — не дублировать в Dart
- Запросы к Supabase — только в `datasources/remote/`

```dart
// ❌ в BLoC или репозитории
final data = await supabase.from('words').select();

// ✅ только в RemoteDataSource
Future<List<WordModel>> fetchWords() async {
  final data = await supabase.from('words').select();
  return data.map(WordModel.fromJson).toList();
}
```

---

## Hive и SharedPreferences

```dart
// Имена боксов — только из AppConstants
final box = Hive.box(AppConstants.wordsBox); // ✅
final box = Hive.box('words_cache');          // ❌

// SharedPreferences — примитивы и флаги
prefs.setBool(AppConstants.guestMode, true);

// Hive — коллекции и кэш
Hive.box(AppConstants.wordsBox).putAll(wordsMap);
```

---

## Локализация

- Языки: `en`, `ru`, `ky`
- Ключи: `camelCase`
- Плейсхолдеры: `{val}` / `{value}`

```dart
// ✅
Text(LocaleKeys.welcomeTitle.tr(context: context))
Text(LocaleKeys.wordProgress.tr(args: [count.toString()]))

// ❌
Text('Добро пожаловать')
```

**Новый текст — 4 шага:**

1. Ключ в `locale_keys.dart`
2. `en.json`
3. `ru.json`
4. `ky.json`

После изменений: `dart run easy_localization:generate`

---

## Ошибки

```dart
// Кастомные исключения в core/errors/
class NetworkException implements Exception {
  const NetworkException([this.message = 'Нет соединения']);
  final String message;
}

// ❌ Глотать ошибки
try { ... } catch (_) {}

// ✅
try { ... } catch (e, st) {
  debugPrint('$e\n$st');
  rethrow;
}
```

---

## Null Safety

```dart
// ❌
final user = supabase.auth.currentUser!;

// ✅
final user = supabase.auth.currentUser;
if (user == null) { emit(const AuthUnauthenticated()); return; }

// ✅ Предпочитай ?. и ??
final name = user?.displayName ?? LocaleKeys.guest.tr();
```

---

## Константы

Всё в `AppConstants` / `SupabaseConstants`. Никаких магических чисел и строк.

```dart
static const double paddingM = 16.0;
static const double paddingL = 24.0;
static const String wordsBox = 'words_box';
static const double minEaseFactor = 1.3;
```

---

## Кодогенерация

```bash
# После изменений @JsonSerializable, @HiveType, @freezed
dart run build_runner build --delete-conflicting-outputs

# После изменений в JSON переводах
dart run easy_localization:generate
```

- `.g.dart` файлы **коммитятся** в git
- `.g.dart` и `.freezed.dart` — **не редактировать вручную**
- CI падает если сгенерированные файлы не закоммичены

---

## Тестирование

| Слой               | Тестируем             |
| ------------------ | --------------------- |
| Domain: Use Cases  | SM-2, вычисления      |
| Domain: Entities   | `copyWith`, `props`   |
| Data: Models       | `fromJson` / `toJson` |
| Data: Repositories | offline-first логика  |
| BLoC               | переходы состояний    |

```dart
// BLoC
blocTest<WordsBloc, WordsState>(
  'emits [loading, loaded] on success',
  build: () => WordsBloc(getWordsForReview: mockUseCase),
  act: (bloc) => bloc.add(const WordLoadRequested()),
  expect: () => [const WordsLoading(), WordsLoaded(tWords)],
);

// Use Case
test('increases ease factor when user knows the word', () {
  final result = applySmResult(progress: tProgress, knew: true);
  expect(result.easeFactor, greaterThan(tProgress.easeFactor));
});
```

Именование тестов — описание поведения: `'returns cached words when network is unavailable'`

---

## Запрещено

```dart
// ❌ Бизнес-логика в виджетах / build()
// ❌ Supabase вне datasource
// ❌ Navigator.push — только GoRouter
// ❌ Хардкод строк в UI — только LocaleKeys без tr() надо так LocaleKeys.key.tr(context: context)
// ❌ Хардкод цветов — только тема
// ❌ Хардкод размеров — только AppConstants
// ❌ Container с одним свойством
// ❌ Widget-метод (_buildSomething) — только Widget-класс в своём файле
// ❌ Импорт data/ из domain/
// ❌ Мутабельные поля (без final)
// ❌ var вместо final
// ❌ dynamic
// ❌ print — только debugPrint
// ❌ setState при наличии BLoC
// ❌ catch (_) {} — не глотать ошибки
```
