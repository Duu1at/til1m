import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:til1m/core/network/connectivity_service.dart';
import 'package:til1m/data/datasources/local/flashcard_local_datasource.dart';
import 'package:til1m/data/datasources/remote/flashcard_remote_datasource.dart';
import 'package:til1m/data/datasources/sync/progress_sync_service.dart';
import 'package:til1m/data/repositories/flashcard_repository_impl.dart';
import 'package:til1m/domain/entities/user_progress.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/entities/word_progress.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';

import '../../helpers/flashcard_test_helpers.dart';

class _MockRemote extends Mock implements FlashcardRemoteDataSource {}

class _MockLocal extends Mock implements FlashcardLocalDataSource {}

class _MockAuth extends Mock implements AuthRepository {}

class _FakeConnectivity extends Fake implements ConnectivityService {
  _FakeConnectivity();
  bool online = true;

  @override
  bool get isOnline => online;
}

class _MockSyncService extends Mock implements ProgressSyncService {}

// ─── Test setup ──────────────────────────────────────────────────────────────

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late _MockAuth auth;
  late _FakeConnectivity connectivity;
  late _MockSyncService syncService;
  late FlashcardRepositoryImpl sut;

  setUpAll(() {
    registerFallbackValue(testUserWordProgress());
    registerFallbackValue(testProgress());
    registerFallbackValue(<UserWordProgress>[]);
    registerFallbackValue(<Word>[]);
    registerFallbackValue(WordLevel.a1);
  });

  FlashcardRepositoryImpl buildRepo({
    bool isGuest = false,
    String? userId = 'user-1',
  }) {
    when(() => auth.isGuest).thenReturn(isGuest);
    when(() => auth.currentUserId).thenReturn(isGuest ? null : userId);
    return FlashcardRepositoryImpl(
      remote: remote,
      local: local,
      authRepo: auth,
      connectivity: connectivity,
      syncService: syncService,
    );
  }

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    auth = _MockAuth();
    connectivity = _FakeConnectivity();
    syncService = _MockSyncService();

    // Common local stubs — won't throw by default.
    when(() => local.cacheWords(any())).thenAnswer((_) async {});
    when(() => local.saveProgress(any())).thenAnswer((_) async {});
    when(
      () => local.getDueProgress(),
    ).thenAnswer((_) async => <WordProgress>[]);
    when(() => local.getCachedWordMap(any())).thenAnswer((_) async => {});
    when(
      () => local.getCachedWords(
        level: any(named: 'level'),
        excludeIds: any(named: 'excludeIds'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => <Word>[]);
    when(() => local.fetchProgressStats()).thenAnswer(
      (_) async => {'known': 0, 'learning': 0, 'today_reviewed': 0, 'due': 0},
    );
    when(
      () => local.getAllProgressWordIds(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => local.getAllProgress(),
    ).thenAnswer((_) async => <WordProgress>[]);
  });

  // ─── Authenticated — online ───────────────────────────────────────────────

  group('authenticated user — online', () {
    setUp(() => sut = buildRepo());

    test(
      'getTodayReviewQueue fetches from remote and caches in Hive',
      () async {
        final wordProgress = testUserWordProgress();
        final word = testWord();
        when(
          () => remote.getWordsForReview(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => [(word: word, progress: wordProgress)]);

        final result = await sut.getTodayReviewQueue('user-1');

        expect(result, hasLength(1));
        expect(result.first.wordId, 'word-1');
        // Should have cached the word locally.
        verify(() => local.cacheWords(any())).called(1);
      },
    );

    test('getNewWords fetches from remote and caches in Hive', () async {
      final words = [testWord(id: 'w1'), testWord(id: 'w2', word: 'banana')];
      when(
        () => remote.getWordsByLevel(
          level: any(named: 'level'),
          excludeIds: any(named: 'excludeIds'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => words);

      final result = await sut.getNewWords(
        level: WordLevel.a1,
        excludeIds: const [],
      );

      expect(result, hasLength(2));
      verify(() => local.cacheWords(any())).called(1);
    });

    test(
      'saveProgress writes to Hive and upserts to Supabase when online',
      () async {
        final progress = testUserWordProgress();
        when(() => remote.saveProgress(any())).thenAnswer((_) async {});
        when(
          () => syncService.removePending(
            userId: any(named: 'userId'),
            wordId: any(named: 'wordId'),
          ),
        ).thenAnswer((_) async {});

        await sut.saveProgress(progress);

        verify(() => local.saveProgress(any())).called(1);
        verify(() => remote.saveProgress(any())).called(1);
      },
    );

    test('saveProgress queues to sync service when Supabase throws', () async {
      final progress = testUserWordProgress();
      when(
        () => remote.saveProgress(any()),
      ).thenThrow(Exception('network error'));
      when(() => syncService.addPending(any())).thenAnswer((_) async {});

      await sut.saveProgress(progress);

      verify(() => local.saveProgress(any())).called(1);
      verify(() => syncService.addPending(any())).called(1);
      verifyNever(
        () => syncService.removePending(
          userId: any(named: 'userId'),
          wordId: any(named: 'wordId'),
        ),
      );
    });
  });

  // ─── Authenticated — offline (remote fails) ───────────────────────────────

  group('authenticated user — offline / remote failure', () {
    setUp(() => sut = buildRepo());

    test('getTodayReviewQueue falls back to Hive when remote throws', () async {
      when(
        () => remote.getWordsForReview(
          userId: any(named: 'userId'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('no connection'));

      // Hive has one due progress entry.
      final dueProgress = testProgress();
      when(
        () => local.getDueProgress(),
      ).thenAnswer((_) async => [dueProgress]);

      final result = await sut.getTodayReviewQueue('user-1');

      expect(result, hasLength(1));
      expect(result.first.wordId, 'word-1');
    });

    test('getNewWords falls back to Hive when remote throws', () async {
      when(
        () => remote.getWordsByLevel(
          level: any(named: 'level'),
          excludeIds: any(named: 'excludeIds'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('no connection'));
      when(
        () => local.getCachedWords(
          level: any(named: 'level'),
          excludeIds: any(named: 'excludeIds'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => [testWord()]);

      final result = await sut.getNewWords(
        level: WordLevel.a1,
        excludeIds: const [],
      );

      expect(result, hasLength(1));
    });

    test('saveProgress queues to sync service when offline', () async {
      connectivity.online = false;
      final progress = testUserWordProgress();
      when(() => syncService.addPending(any())).thenAnswer((_) async {});

      await sut.saveProgress(progress);

      // Local must always be written.
      verify(() => local.saveProgress(any())).called(1);
      // Remote must never be called when offline.
      verifyNever(() => remote.saveProgress(any()));
      // Must be queued for later sync.
      verify(() => syncService.addPending(any())).called(1);
    });
  });

  // ─── Guest mode ───────────────────────────────────────────────────────────

  group('guest user', () {
    setUp(() => sut = buildRepo(isGuest: true, userId: null));

    test(
      'getTodayReviewQueue reads only from Hive — remote is never called',
      () async {
        when(
          () => local.getDueProgress(),
        ).thenAnswer((_) async => [testProgress()]);

        final result = await sut.getTodayReviewQueue('guest');

        expect(result, hasLength(1));
        verifyNever(
          () => remote.getWordsForReview(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
          ),
        );
      },
    );

    test('getNewWords reads only from Hive — remote is never called', () async {
      when(
        () => local.getCachedWords(
          level: any(named: 'level'),
          excludeIds: any(named: 'excludeIds'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => [testWord()]);

      final result = await sut.getNewWords(
        level: WordLevel.a1,
        excludeIds: const [],
      );

      expect(result, hasLength(1));
      verifyNever(
        () => remote.getWordsByLevel(
          level: any(named: 'level'),
          excludeIds: any(named: 'excludeIds'),
          limit: any(named: 'limit'),
        ),
      );
    });

    test('saveProgress writes only to Hive — remote is never called', () async {
      final progress = testUserWordProgress(userId: 'guest');

      await sut.saveProgress(progress);

      verify(() => local.saveProgress(any())).called(1);
      verifyNever(() => remote.saveProgress(any()));
      verifyNever(() => syncService.addPending(any()));
    });
  });

  // ─── saveProgress UPSERT semantics ────────────────────────────────────────

  group('saveProgress — UPSERT behaviour', () {
    setUp(() => sut = buildRepo());

    test(
      'calling saveProgress twice for the same word triggers two writes (upsert)',
      () async {
        when(() => remote.saveProgress(any())).thenAnswer((_) async {});
        when(
          () => syncService.removePending(
            userId: any(named: 'userId'),
            wordId: any(named: 'wordId'),
          ),
        ).thenAnswer((_) async {});

        final first = testUserWordProgress(repetitions: 1);
        final second = testUserWordProgress(repetitions: 2);

        await sut.saveProgress(first);
        await sut.saveProgress(second);

        verify(() => local.saveProgress(any())).called(2);
        verify(() => remote.saveProgress(any())).called(2);
      },
    );

    test(
      'applySmResult fetches current progress, applies SM-2, and saves result',
      () async {
        // Simulate no existing progress.
        when(
          () => remote.getProgressForWord(
            userId: any(named: 'userId'),
            wordId: any(named: 'wordId'),
          ),
        ).thenAnswer((_) async => null);
        when(() => remote.saveProgress(any())).thenAnswer((_) async {});
        when(
          () => syncService.removePending(
            userId: any(named: 'userId'),
            wordId: any(named: 'wordId'),
          ),
        ).thenAnswer((_) async {});

        await sut.applySmResult(
          userId: 'user-1',
          wordId: 'word-1',
          knew: true,
        );

        // After applying SM-2 for a brand-new word with correct answer:
        // repetitions should be 1 — verified by inspecting what was saved.
        final captured = verify(
          () => local.saveProgress(captureAny()),
        ).captured;
        expect(captured, isNotEmpty);
        final saved = captured.first as WordProgress;
        expect(saved.repetitions, 1);
        expect(saved.status, WordStatus.learning);
      },
    );
  });
}
