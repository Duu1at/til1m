import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:til1m/domain/entities/translation.dart';
import 'package:til1m/domain/entities/word_example.dart';
import 'package:til1m/presentation/widgets/flashcard/back_face.dart';
import 'package:til1m/presentation/widgets/flashcard/flashcard_card.dart';
import 'package:til1m/presentation/widgets/flashcard/flashcard_front_face.dart';

import '../../helpers/flashcard_test_helpers.dart';

// ─── Inline asset loader ──────────────────────────────────────────────────────

/// Provides hardcoded Russian translations so tests don't depend on the file
/// system asset loading order.
class _InlineLoader extends AssetLoader {
  const _InlineLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => const {
    'word': {
      'btn_flip': 'Показать ответ',
      'btn_know': 'Знаю',
      'btn_dont_know': 'Не знаю',
      'audio_play': 'Произношение',
      'examples': 'Примеры',
    },
  };
}

// ─── Pump helper ─────────────────────────────────────────────────────────────

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ru')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ru'),
      assetLoader: const _InlineLoader(),
      child: MaterialApp(
        locale: const Locale('ru'),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ─── Shared fixtures ─────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    await EasyLocalization.ensureInitialized();
  });

  final word = testWord(
    id: 'w1',
    translations: const [
      Translation(
        language: TranslationLanguage.ru,
        translation: 'яблоко',
        synonyms: ['фрукт'],
      ),
    ],
    examples: const [
      WordExample(exampleEn: 'An apple a day.', exampleRu: 'Яблоко в день.'),
    ],
  );

  final progress = testProgress(wordId: 'w1');

  // ─── FlashcardFrontFace ──────────────────────────────────────────────────

  group('FlashcardFrontFace', () {
    testWidgets('displays the english word', (tester) async {
      await _pump(
        tester,
        FlashcardFrontFace(
          word: word,
          progress: progress,
          isCurrentReview: false,
          isAudioPlaying: false,
          onFlip: () {},
          onAudio: () {},
        ),
      );

      expect(find.text('apple'), findsOneWidget);
    });

    testWidgets('displays transcription wrapped in square brackets', (
      tester,
    ) async {
      await _pump(
        tester,
        FlashcardFrontFace(
          word: word,
          progress: progress,
          isCurrentReview: false,
          isAudioPlaying: false,
          onFlip: () {},
          onAudio: () {},
        ),
      );

      expect(find.text('[ˈæp.əl]'), findsOneWidget);
    });

    testWidgets('does not show transcription row when transcription is null', (
      tester,
    ) async {
      final noTranscriptionWord = testWord(id: 'w2', transcription: null);

      await _pump(
        tester,
        FlashcardFrontFace(
          word: noTranscriptionWord,
          progress: progress,
          isCurrentReview: false,
          isAudioPlaying: false,
          onFlip: () {},
          onAudio: () {},
        ),
      );

      expect(find.textContaining('['), findsNothing);
    });

    testWidgets('shows volume icon button when not playing audio', (
      tester,
    ) async {
      await _pump(
        tester,
        FlashcardFrontFace(
          word: word,
          progress: progress,
          isCurrentReview: false,
          isAudioPlaying: false,
          onFlip: () {},
          onAudio: () {},
        ),
      );

      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets(
      'shows CircularProgressIndicator and no volume icon while audio is playing',
      (tester) async {
        await _pump(
          tester,
          FlashcardFrontFace(
            word: word,
            progress: progress,
            isCurrentReview: false,
            isAudioPlaying: true,
            onFlip: () {},
            onAudio: () {},
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
      },
    );

    testWidgets('tapping the flip FilledButton calls onFlip', (tester) async {
      var called = false;

      await _pump(
        tester,
        FlashcardFrontFace(
          word: word,
          progress: progress,
          isCurrentReview: false,
          isAudioPlaying: false,
          onFlip: () => called = true,
          onAudio: () {},
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('tapping the audio IconButton calls onAudio', (tester) async {
      var called = false;

      await _pump(
        tester,
        FlashcardFrontFace(
          word: word,
          progress: progress,
          isCurrentReview: false,
          isAudioPlaying: false,
          onFlip: () {},
          onAudio: () => called = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump();

      expect(called, isTrue);
    });
  });

  // ─── BackFace ─────────────────────────────────────────────────────────────

  group('BackFace', () {
    testWidgets('shows russian translation text', (tester) async {
      await _pump(
        tester,
        BackFace(word: word, onKnow: () {}, onDontKnow: () {}),
      );

      expect(find.text('яблоко'), findsOneWidget);
    });

    testWidgets('shows the english word on the back', (tester) async {
      await _pump(
        tester,
        BackFace(word: word, onKnow: () {}, onDontKnow: () {}),
      );

      expect(find.text('apple'), findsOneWidget);
    });

    testWidgets('tapping the check icon (Знаю) calls onKnow', (tester) async {
      var called = false;

      await _pump(
        tester,
        BackFace(
          word: word,
          onKnow: () => called = true,
          onDontKnow: () {},
        ),
      );

      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('tapping the close icon (Не знаю) calls onDontKnow', (
      tester,
    ) async {
      var called = false;

      await _pump(
        tester,
        BackFace(
          word: word,
          onKnow: () {},
          onDontKnow: () => called = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('shows synonyms when the translation has them', (tester) async {
      await _pump(
        tester,
        BackFace(word: word, onKnow: () {}, onDontKnow: () {}),
      );

      expect(find.textContaining('фрукт'), findsOneWidget);
    });

    testWidgets('does not show synonyms when translation has none', (
      tester,
    ) async {
      final wordNoSynonyms = testWord(
        id: 'w3',
        translations: const [
          Translation(
            language: TranslationLanguage.ru,
            translation: 'яблоко',
          ),
        ],
      );

      await _pump(
        tester,
        BackFace(word: wordNoSynonyms, onKnow: () {}, onDontKnow: () {}),
      );

      expect(find.textContaining('фрукт'), findsNothing);
    });
  });

  // ─── FlashcardCard (composed) ────────────────────────────────────────────

  group('FlashcardCard', () {
    testWidgets('shows FlashcardFrontFace when isFlipped is false', (
      tester,
    ) async {
      await _pump(
        tester,
        FlashcardCard(
          word: word,
          progress: progress,
          isCurrentReview: false,
          isFlipped: false,
          isAudioPlaying: false,
          onFlip: () {},
          onKnow: () {},
          onDontKnow: () {},
          onAudio: () {},
        ),
      );

      expect(find.byType(FlashcardFrontFace), findsOneWidget);
      expect(find.byType(BackFace), findsNothing);
    });

    testWidgets('shows BackFace immediately when isFlipped starts as true', (
      tester,
    ) async {
      await _pump(
        tester,
        FlashcardCard(
          word: word,
          progress: progress,
          isCurrentReview: false,
          isFlipped: true,
          isAudioPlaying: false,
          onFlip: () {},
          onKnow: () {},
          onDontKnow: () {},
          onAudio: () {},
        ),
      );

      expect(find.byType(BackFace), findsOneWidget);
      expect(find.byType(FlashcardFrontFace), findsNothing);
    });

    testWidgets(
      'onKnow callback fires when tapping check icon on the back face',
      (tester) async {
        var called = false;

        await _pump(
          tester,
          FlashcardCard(
            word: word,
            progress: progress,
            isCurrentReview: false,
            isFlipped: true,
            isAudioPlaying: false,
            onFlip: () {},
            onKnow: () => called = true,
            onDontKnow: () {},
            onAudio: () {},
          ),
        );

        await tester.tap(find.byIcon(Icons.check_rounded));
        await tester.pump();

        expect(called, isTrue);
      },
    );

    testWidgets(
      'onDontKnow callback fires when tapping close icon on the back face',
      (tester) async {
        var called = false;

        await _pump(
          tester,
          FlashcardCard(
            word: word,
            progress: progress,
            isCurrentReview: false,
            isFlipped: true,
            isAudioPlaying: false,
            onFlip: () {},
            onKnow: () {},
            onDontKnow: () => called = true,
            onAudio: () {},
          ),
        );

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pump();

        expect(called, isTrue);
      },
    );

    testWidgets('word text is visible on the front face', (tester) async {
      await _pump(
        tester,
        FlashcardCard(
          word: word,
          progress: progress,
          isCurrentReview: false,
          isFlipped: false,
          isAudioPlaying: false,
          onFlip: () {},
          onKnow: () {},
          onDontKnow: () {},
          onAudio: () {},
        ),
      );

      expect(find.text('apple'), findsOneWidget);
    });
  });
}
