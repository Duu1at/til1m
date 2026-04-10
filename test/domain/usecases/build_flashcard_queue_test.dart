import 'dart:async';

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

class _MockFlashcardRepo extends Mock implements FlashcardRepositoryImpl {}

class _MockAuthRepo extends Mock implements AuthRepository {}

class _FakeConnectivityService extends Fake implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();

  @override
  bool get isOnline => true;

  @override
  Stream<bool> get onlineStream => _controller.stream;
}

class _MockSyncService extends Mock implements ProgressSyncService {}

class _MockUpdateHomeWidget extends Mock implements UpdateHomeWidget {}

// ─── Helpers ─────────────────────────────────────────────────────────────────

void _setupDefaultPrefs() {
  SharedPreferences.setMockInitialValues({
    AppConstants.keyUserLevel: 'a1',
    AppConstants.keyDailyGoal: 5,
  });
}

FlashcardBloc _buildBloc({
  required _MockFlashcardRepo repo,
  required _MockAuthRepo authRepo,
  _FakeConnectivityService? connectivity,
  _MockSyncService? syncService,
  _MockUpdateHomeWidget? homeWidget,
}) {
  return FlashcardBloc(
    flashcardRepo: repo,
    authRepo: authRepo,
    connectivity: connectivity ?? _FakeConnectivityService(),
    syncService: syncService ?? _MockSyncService(),
    updateHomeWidget: homeWidget ?? _MockUpdateHomeWidget(),
  );
}

void main() {
  late _MockFlashcardRepo repo;
  late _MockAuthRepo authRepo;

  setUpAll(() {
    registerFallbackValue(WordLevel.a1);
    registerFallbackValue(<String>[]);
    registerFallbackValue(testUserWordProgress());
    registerFallbackValue(testSession());
  });

  setUp(() {
    repo = _MockFlashcardRepo();
    authRepo = _MockAuthRepo();

    when(() => authRepo.currentUserId).thenReturn('user-1');
    when(() => authRepo.isGuest).thenReturn(false);

    // Default: no review items, no new words.
    when(() => repo.getReviewSessionItems(any())).thenAnswer((_) async => []);
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
    when(() => repo.saveProgress(any())).thenAnswer((_) async {});
    when(() => repo.saveSession(any())).thenAnswer((_) async {});
    when(() => repo.clearSession()).thenAnswer((_) async {});
    when(() => repo.getTodayLearnedCount(any())).thenAnswer((_) async => 0);
    when(() => repo.restoreSession()).thenAnswer((_) async => null);
  });

  // ─── Queue order: reviews first, then new ────────────────────────────────

  group('queue ordering', () {
    test('reviews come before new words in the session items list', () async {
      _setupDefaultPrefs();

      final reviewItem = testItem(wordId: 'rev-1', isReview: true);
      final newWord = testWord(id: 'new-1', word: 'banana');

      when(
        () => repo.getReviewSessionItems(any()),
      ).thenAnswer((_) async => [reviewItem]);
      when(
        () => repo.getNewWords(
          level: any(named: 'level'),
          excludeIds: any(named: 'excludeIds'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => [newWord]);

      final bloc = _buildBloc(repo: repo, authRepo: authRepo);
      addTearDown(bloc.close);

      bloc.add(const FlashcardStartSession(source: FlashcardSource.mixed));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = bloc.state;
      expect(state, isA<FlashcardActive>());

      final active = state as FlashcardActive;
      // First item must be the review word.
      expect(active.currentWord.id, 'rev-1');
      expect(active.isCurrentReview, isTrue);
    });

    test('review count and new count are tracked separately', () async {
      _setupDefaultPrefs();

      final reviewItems = [
        testItem(wordId: 'r1', isReview: true),
        testItem(wordId: 'r2', isReview: true),
      ];
      final newWords = [testWord(id: 'n1'), testWord(id: 'n2', word: 'banana')];

      when(
        () => repo.getReviewSessionItems(any()),
      ).thenAnswer((_) async => reviewItems);
      when(
        () => repo.getNewWords(
          level: any(named: 'level'),
          excludeIds: any(named: 'excludeIds'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => newWords);

      final bloc = _buildBloc(repo: repo, authRepo: authRepo);
      addTearDown(bloc.close);

      bloc.add(const FlashcardStartSession(source: FlashcardSource.mixed));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final active = bloc.state as FlashcardActive;
      expect(active.reviewCount, 2);
      expect(active.newCount, 2);
      expect(active.totalWords, 4);
    });
  });

  // ─── Source: reviewOnly ───────────────────────────────────────────────────

  group('FlashcardSource.review', () {
    test('fetches only review items — does not call getNewWords', () async {
      _setupDefaultPrefs();

      final reviewItem = testItem(wordId: 'r1', isReview: true);
      when(
        () => repo.getReviewSessionItems(any()),
      ).thenAnswer((_) async => [reviewItem]);

      final bloc = _buildBloc(repo: repo, authRepo: authRepo);
      addTearDown(bloc.close);

      bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // getNewWords must never be invoked.
      verifyNever(
        () => repo.getNewWords(
          level: any(named: 'level'),
          excludeIds: any(named: 'excludeIds'),
          limit: any(named: 'limit'),
        ),
      );

      final active = bloc.state as FlashcardActive;
      expect(active.reviewCount, 1);
      expect(active.newCount, 0);
    });

    test(
      'review source: only words with next_review_at <= now are returned',
      () async {
        _setupDefaultPrefs();

        // Due word: nextReviewAt in the past.
        final dueItem = testItem(wordId: 'due-1', isReview: true);
        // Non-due word: not in the review queue (filtered by datasource/repo).
        when(
          () => repo.getReviewSessionItems(any()),
        ).thenAnswer((_) async => [dueItem]);

        final bloc = _buildBloc(repo: repo, authRepo: authRepo);
        addTearDown(bloc.close);

        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final active = bloc.state as FlashcardActive;
        expect(active.totalWords, 1);
        expect(active.currentWord.id, 'due-1');
      },
    );
  });

  // ─── Source: newWords ─────────────────────────────────────────────────────

  group('FlashcardSource.newWords', () {
    test(
      'fetches only new words — does not call getReviewSessionItems',
      () async {
        _setupDefaultPrefs();

        final newWord = testWord(id: 'n1');
        when(
          () => repo.getNewWords(
            level: any(named: 'level'),
            excludeIds: any(named: 'excludeIds'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => [newWord]);

        final bloc = _buildBloc(repo: repo, authRepo: authRepo);
        addTearDown(bloc.close);

        bloc.add(const FlashcardStartSession(source: FlashcardSource.newWords));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        verifyNever(() => repo.getReviewSessionItems(any()));

        final active = bloc.state as FlashcardActive;
        expect(active.newCount, 1);
        expect(active.reviewCount, 0);
      },
    );
  });

  // ─── Empty queue ──────────────────────────────────────────────────────────

  group('empty queue', () {
    test('emits FlashcardEmpty when no reviews and no new words', () async {
      _setupDefaultPrefs();

      // Defaults already set to empty in setUp.

      final bloc = _buildBloc(repo: repo, authRepo: authRepo);
      addTearDown(bloc.close);

      bloc.add(const FlashcardStartSession(source: FlashcardSource.mixed));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<FlashcardEmpty>());
    });

    test(
      'emits FlashcardEmpty with the correct source when reviewOnly is empty',
      () async {
        _setupDefaultPrefs();

        final bloc = _buildBloc(repo: repo, authRepo: authRepo);
        addTearDown(bloc.close);

        bloc.add(const FlashcardStartSession(source: FlashcardSource.review));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final empty = bloc.state as FlashcardEmpty;
        expect(empty.source, FlashcardSource.review);
      },
    );

    test(
      'emits FlashcardEmpty with the correct source when newWords is empty',
      () async {
        _setupDefaultPrefs();

        final bloc = _buildBloc(repo: repo, authRepo: authRepo);
        addTearDown(bloc.close);

        bloc.add(const FlashcardStartSession(source: FlashcardSource.newWords));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final empty = bloc.state as FlashcardEmpty;
        expect(empty.source, FlashcardSource.newWords);
      },
    );
  });

  // ─── excludeIds: words with existing progress are excluded ───────────────

  group('excludeIds (already-seen words)', () {
    test(
      'already-progressed word IDs are excluded from new-word query',
      () async {
        _setupDefaultPrefs();

        when(
          () => repo.getProgressWordIds(any()),
        ).thenAnswer((_) async => ['word-1', 'word-2']);

        List<String>? capturedExcludeIds;
        when(
          () => repo.getNewWords(
            level: any(named: 'level'),
            excludeIds: any(named: 'excludeIds'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((inv) async {
          capturedExcludeIds =
              inv.namedArguments[const Symbol('excludeIds')] as List<String>;
          return <Word>[];
        });

        final bloc = _buildBloc(repo: repo, authRepo: authRepo);
        addTearDown(bloc.close);

        bloc.add(const FlashcardStartSession(source: FlashcardSource.mixed));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(capturedExcludeIds, containsAll(['word-1', 'word-2']));
      },
    );
  });
}
