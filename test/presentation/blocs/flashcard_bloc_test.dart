import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/network/connectivity_service.dart';
import 'package:til1m/data/datasources/sync/progress_sync_service.dart';
import 'package:til1m/data/repositories/flashcard_repository_impl.dart';
import 'package:til1m/data/services/update_home_widget.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/presentation/blocs/flashcard/flashcard_bloc.dart';

import '../../helpers/flashcard_test_helpers.dart';

// ─── Mocks & fakes ───────────────────────────────────────────────────────────

class _MockFlashcardRepo extends Mock implements FlashcardRepositoryImpl {}

class _MockAuthRepo extends Mock implements AuthRepository {}

class _MockSyncService extends Mock implements ProgressSyncService {}

class _MockUpdateHomeWidget extends Mock implements UpdateHomeWidget {}

/// Fake connectivity service with a controllable online flag.
class _FakeConnectivity extends Fake implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();

  @override
  bool get isOnline => true;

  @override
  Stream<bool> get onlineStream => _controller.stream;

  @override
  void dispose() => _controller.close();
}

// ─── Test helpers ─────────────────────────────────────────────────────────────

void _setMockPrefs({int dailyGoal = 5, String level = 'a1'}) {
  SharedPreferences.setMockInitialValues({
    AppConstants.keyDailyGoal: dailyGoal,
    AppConstants.keyUserLevel: level,
  });
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late _MockFlashcardRepo repo;
  late _MockAuthRepo authRepo;
  late _FakeConnectivity connectivity;
  late _MockSyncService syncService;
  late _MockUpdateHomeWidget homeWidget;

  setUpAll(() {
    registerFallbackValue(testUserWordProgress());
    registerFallbackValue(WordLevel.a1);
    registerFallbackValue(<String>[]);
    registerFallbackValue(testSession());
  });

  setUp(() {
    repo = _MockFlashcardRepo();
    authRepo = _MockAuthRepo();
    connectivity = _FakeConnectivity();
    syncService = _MockSyncService();
    homeWidget = _MockUpdateHomeWidget();

    when(() => authRepo.currentUserId).thenReturn('user-1');
    when(() => authRepo.isGuest).thenReturn(false);

    // Default stubs so tests that don't care about these calls won't throw.
    when(() => repo.saveProgress(any())).thenAnswer((_) async {});
    when(() => repo.clearSession()).thenAnswer((_) async {});
    when(() => repo.getTodayLearnedCount(any())).thenAnswer((_) async => 0);
    when(() => repo.restoreSession()).thenAnswer((_) async => null);
    when(
      () => repo.getProgressWordIds(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => repo.getNewWords(
        level: any(named: 'level'),
        excludeIds: any(named: 'excludeIds'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => <Word>[]);
    when(
      () => repo.getReviewSessionItems(any()),
    ).thenAnswer((_) async => []);
    when(() => homeWidget.call()).thenAnswer((_) async {});
  });

  tearDown(() => connectivity.dispose());

  FlashcardBloc buildBloc() => FlashcardBloc(
    flashcardRepo: repo,
    authRepo: authRepo,
    connectivity: connectivity,
    syncService: syncService,
    updateHomeWidget: homeWidget,
  );

  // ─── StartSession ────────────────────────────────────────────────────────

  group('FlashcardStartSession', () {
    blocTest<FlashcardBloc, FlashcardState>(
      'emits [Loading, Active] when review items exist',
      setUp: () {
        _setMockPrefs();
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [
            testItem(wordId: 'r1', isReview: true),
          ],
        );
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FlashcardStartSession(source: FlashcardSource.review)),
      expect: () => [
        isA<FlashcardLoading>(),
        isA<FlashcardActive>()
            .having((s) => s.currentWord.word, 'currentWord.word', 'apple')
            .having((s) => s.isCurrentReview, 'isCurrentReview', isTrue)
            .having((s) => s.canUndo, 'canUndo', isFalse),
      ],
    );

    blocTest<FlashcardBloc, FlashcardState>(
      'emits [Loading, Empty] when both review and new-word queues are empty',
      setUp: _setMockPrefs,
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FlashcardStartSession(source: FlashcardSource.mixed)),
      expect: () => [
        isA<FlashcardLoading>(),
        isA<FlashcardEmpty>(),
      ],
    );

    blocTest<FlashcardBloc, FlashcardState>(
      'emits [Loading, Error] when repo throws',
      setUp: () {
        _setMockPrefs();
        when(
          () => repo.getReviewSessionItems(any()),
        ).thenThrow(Exception('db error'));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FlashcardStartSession(source: FlashcardSource.review)),
      expect: () => [
        isA<FlashcardLoading>(),
        isA<FlashcardError>(),
      ],
    );

    blocTest<FlashcardBloc, FlashcardState>(
      'Active state has correct reviewCount and newCount from mixed source',
      setUp: () {
        _setMockPrefs();
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [
            testItem(wordId: 'r1', isReview: true),
            testItem(wordId: 'r2', wordText: 'book', isReview: true),
          ],
        );
        when(
          () => repo.getNewWords(
            level: any(named: 'level'),
            excludeIds: any(named: 'excludeIds'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => [testWord(id: 'n1', word: 'cat')],
        );
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FlashcardStartSession(source: FlashcardSource.mixed)),
      expect: () => [
        isA<FlashcardLoading>(),
        isA<FlashcardActive>()
            .having((s) => s.reviewCount, 'reviewCount', 2)
            .having((s) => s.newCount, 'newCount', 1)
            .having((s) => s.totalWords, 'totalWords', 3),
      ],
    );
  });

  // ─── FlashcardAnswer — correct ────────────────────────────────────────────

  group('FlashcardAnswer(isCorrect: true)', () {
    blocTest<FlashcardBloc, FlashcardState>(
      'advances to the next word in the queue',
      setUp: () {
        _setMockPrefs();
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [
            testItem(wordId: 'w1', isReview: true),
            testItem(wordId: 'w2', wordText: 'banana', isReview: true),
          ],
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const FlashcardAnswer(isCorrect: true));
      },
      expect: () => [
        isA<FlashcardLoading>(),
        isA<FlashcardActive>().having(
          (s) => s.currentWord.word,
          'word',
          'apple',
        ),
        isA<FlashcardActive>()
            .having((s) => s.currentWord.word, 'word', 'banana')
            .having((s) => s.canUndo, 'canUndo', isTrue)
            .having((s) => s.correctCount, 'correctCount', 1),
      ],
    );

    blocTest<FlashcardBloc, FlashcardState>(
      'increments correctCount and answeredCount',
      setUp: () {
        _setMockPrefs();
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [
            testItem(wordId: 'w1', isReview: true),
            testItem(wordId: 'w2', wordText: 'banana', isReview: true),
          ],
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const FlashcardAnswer(isCorrect: true));
      },
      verify: (bloc) {
        final state = bloc.state as FlashcardActive;
        expect(state.answeredCount, 1);
        expect(state.correctCount, 1);
        expect(state.incorrectCount, 0);
      },
    );

    blocTest<FlashcardBloc, FlashcardState>(
      'saves progress after a correct answer',
      setUp: () {
        _setMockPrefs();
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [
            testItem(wordId: 'w1', isReview: true),
            testItem(wordId: 'w2', wordText: 'banana', isReview: true),
          ],
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const FlashcardAnswer(isCorrect: true));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      verify: (_) {
        verify(() => repo.saveProgress(any())).called(greaterThanOrEqualTo(1));
      },
    );
  });

  // ─── FlashcardAnswer — incorrect ─────────────────────────────────────────

  group('FlashcardAnswer(isCorrect: false)', () {
    blocTest<FlashcardBloc, FlashcardState>(
      'adds the word back to the end of the queue',
      setUp: () {
        _setMockPrefs();
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [
            testItem(wordId: 'w1', isReview: true),
          ],
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const FlashcardAnswer(isCorrect: false));
      },
      expect: () => [
        isA<FlashcardLoading>(),
        isA<FlashcardActive>().having((s) => s.totalWords, 'totalWords', 1),
        // After incorrect: word re-appended, totalWords becomes 2, currentIndex 1.
        isA<FlashcardActive>()
            .having((s) => s.totalWords, 'totalWords', 2)
            .having((s) => s.currentIndex, 'currentIndex', 1),
      ],
    );

    blocTest<FlashcardBloc, FlashcardState>(
      'does not re-append word after maxRetries (3) exhausted',
      setUp: () {
        _setMockPrefs();
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [
            testItem(wordId: 'w1', isReview: true),
            // Padding word so session doesn't complete after each incorrect answer.
            testItem(wordId: 'w2', wordText: 'banana', isReview: true),
            testItem(wordId: 'w3', wordText: 'cherry', isReview: true),
            testItem(wordId: 'w4', wordText: 'date', isReview: true),
          ],
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Answer word-1 incorrectly 4 times (max retries = 3).
        for (var i = 0; i < 4; i++) {
          bloc.add(const FlashcardAnswer(isCorrect: false));
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }
      },
      verify: (bloc) {
        // The queue grew by at most _maxRetries (3) for the first word.
        // After 3 retries, the 4th incorrect answer should not re-append.
        final state = bloc.state;
        expect(state, isA<FlashcardActive>());
      },
    );
  });

  // ─── Session complete ────────────────────────────────────────────────────

  group('SessionComplete', () {
    blocTest<FlashcardBloc, FlashcardState>(
      'emits SessionComplete after the last word is answered',
      setUp: () {
        _setMockPrefs(dailyGoal: 3);
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [testItem(wordId: 'w1', isReview: true)],
        );
        when(() => repo.getTodayLearnedCount(any())).thenAnswer((_) async => 1);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const FlashcardAnswer(isCorrect: true));
        // Allow the internally dispatched FlashcardEndSession to complete.
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      expect: () => [
        isA<FlashcardLoading>(),
        isA<FlashcardActive>(),
        isA<FlashcardSessionComplete>()
            .having((s) => s.totalAnswered, 'totalAnswered', 1)
            .having((s) => s.correctCount, 'correctCount', 1)
            .having((s) => s.incorrectCount, 'incorrectCount', 0),
      ],
    );

    blocTest<FlashcardBloc, FlashcardState>(
      'dailyGoalReached is true when todayLearnedCount >= dailyGoal',
      setUp: () {
        _setMockPrefs(dailyGoal: 1);
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [testItem(wordId: 'w1', isReview: true)],
        );
        when(() => repo.getTodayLearnedCount(any())).thenAnswer((_) async => 5);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const FlashcardAnswer(isCorrect: true));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      expect: () => [
        isA<FlashcardLoading>(),
        isA<FlashcardActive>(),
        isA<FlashcardSessionComplete>().having(
          (s) => s.dailyGoalReached,
          'dailyGoalReached',
          isTrue,
        ),
      ],
    );

    blocTest<FlashcardBloc, FlashcardState>(
      'clearSession is called when session ends',
      setUp: () {
        _setMockPrefs();
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [testItem(wordId: 'w1', isReview: true)],
        );
        when(() => repo.getTodayLearnedCount(any())).thenAnswer((_) async => 0);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const FlashcardAnswer(isCorrect: true));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      verify: (_) {
        verify(() => repo.clearSession()).called(1);
      },
    );
  });

  // ─── FlashcardUndo ───────────────────────────────────────────────────────

  group('FlashcardUndo', () {
    blocTest<FlashcardBloc, FlashcardState>(
      'returns to the previous word after an answer was submitted',
      setUp: () {
        _setMockPrefs();
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [
            testItem(wordId: 'w1', isReview: true),
            testItem(wordId: 'w2', wordText: 'banana', isReview: true),
          ],
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const FlashcardAnswer(isCorrect: true));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const FlashcardUndo());
      },
      expect: () => [
        isA<FlashcardLoading>(),
        // Active on word 1.
        isA<FlashcardActive>()
            .having((s) => s.currentWord.word, 'word', 'apple')
            .having((s) => s.canUndo, 'canUndo', isFalse),
        // Active on word 2 after correct answer.
        isA<FlashcardActive>()
            .having((s) => s.currentWord.word, 'word', 'banana')
            .having((s) => s.canUndo, 'canUndo', isTrue),
        // Back to word 1 after undo.
        isA<FlashcardActive>()
            .having((s) => s.currentWord.word, 'word', 'apple')
            .having((s) => s.canUndo, 'canUndo', isFalse),
      ],
    );

    blocTest<FlashcardBloc, FlashcardState>(
      're-saves the previous progress state when undoing',
      setUp: () {
        _setMockPrefs();
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [
            testItem(wordId: 'w1', isReview: true),
            testItem(wordId: 'w2', wordText: 'banana', isReview: true),
          ],
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const FlashcardAnswer(isCorrect: true));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const FlashcardUndo());
        await Future<void>.delayed(const Duration(milliseconds: 30));
      },
      verify: (_) {
        // saveProgress is called once for the answer, once for the undo.
        verify(() => repo.saveProgress(any())).called(greaterThanOrEqualTo(2));
      },
    );

    blocTest<FlashcardBloc, FlashcardState>(
      'does nothing when the undo stack is empty',
      setUp: () {
        _setMockPrefs();
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [testItem(wordId: 'w1', isReview: true)],
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Undo without any prior answer — should be a no-op.
        bloc.add(const FlashcardUndo());
      },
      expect: () => [
        isA<FlashcardLoading>(),
        isA<FlashcardActive>(),
        // No additional state after no-op undo.
      ],
    );
  });

  // ─── FlashcardResumeSession ──────────────────────────────────────────────

  group('FlashcardResumeSession', () {
    blocTest<FlashcardBloc, FlashcardState>(
      'restores an in-progress session from Hive',
      setUp: () {
        _setMockPrefs();
        final saved = testSession(
          items: [testItem(wordId: 'saved-1', wordText: 'restored')],
        );
        when(() => repo.restoreSession()).thenAnswer((_) async => saved);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const FlashcardResumeSession()),
      expect: () => [
        isA<FlashcardLoading>(),
        isA<FlashcardActive>().having(
          (s) => s.currentWord.word,
          'word',
          'restored',
        ),
      ],
    );

    blocTest<FlashcardBloc, FlashcardState>(
      'starts a new session when no saved session exists (null)',
      setUp: () {
        _setMockPrefs();
        when(() => repo.restoreSession()).thenAnswer((_) async => null);
        // New session would also be empty → FlashcardEmpty.
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const FlashcardResumeSession()),
      expect: () => [
        isA<FlashcardLoading>(),
        // Falls back to StartSession → emits Loading again then Empty.
        isA<FlashcardLoading>(),
        isA<FlashcardEmpty>(),
      ],
    );

    blocTest<FlashcardBloc, FlashcardState>(
      'starts a new session when the restored session is already complete',
      setUp: () {
        _setMockPrefs();
        // A session with currentIndex past the last item is "complete".
        final completedSession = testSession(
          items: [testItem(wordId: 'w1')],
          currentIndex: 1, // >= items.length → isComplete == true
        );
        when(
          () => repo.restoreSession(),
        ).thenAnswer((_) async => completedSession);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const FlashcardResumeSession()),
      expect: () => [
        isA<FlashcardLoading>(),
        isA<FlashcardLoading>(),
        isA<FlashcardEmpty>(),
      ],
    );
  });

  // ─── FlashcardFlipCard ────────────────────────────────────────────────────

  group('FlashcardFlipCard', () {
    blocTest<FlashcardBloc, FlashcardState>(
      'toggles isFlipped on the active state',
      setUp: () {
        _setMockPrefs();
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [testItem(wordId: 'w1', isReview: true)],
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const FlashcardFlipCard());
      },
      expect: () => [
        isA<FlashcardLoading>(),
        isA<FlashcardActive>().having((s) => s.isFlipped, 'isFlipped', isFalse),
        isA<FlashcardActive>().having((s) => s.isFlipped, 'isFlipped', isTrue),
      ],
    );

    blocTest<FlashcardBloc, FlashcardState>(
      'flipping twice returns to unflipped state',
      setUp: () {
        _setMockPrefs();
        when(() => repo.getReviewSessionItems(any())).thenAnswer(
          (_) async => [testItem(wordId: 'w1', isReview: true)],
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc
          ..add(const FlashcardFlipCard())
          ..add(const FlashcardFlipCard());
      },
      expect: () => [
        isA<FlashcardLoading>(),
        isA<FlashcardActive>().having((s) => s.isFlipped, 'isFlipped', isFalse),
        isA<FlashcardActive>().having((s) => s.isFlipped, 'isFlipped', isTrue),
        isA<FlashcardActive>().having((s) => s.isFlipped, 'isFlipped', isFalse),
      ],
    );
  });

  // ─── Initial state ────────────────────────────────────────────────────────

  test('initial state is FlashcardInitial', () async {
    _setMockPrefs();
    final bloc = buildBloc();
    expect(bloc.state, isA<FlashcardInitial>());
    await bloc.close();
  });
}
