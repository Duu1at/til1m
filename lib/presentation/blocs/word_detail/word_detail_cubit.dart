import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/supabase_constants.dart';
import 'package:til1m/data/datasources/local/progress_local_datasource.dart';
import 'package:til1m/data/datasources/remote/progress_remote_datasource.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/domain/repositories/word_repository.dart';

part 'word_detail_state.dart';

final class WordDetailCubit extends Cubit<WordDetailState> {
  WordDetailCubit({
    required WordRepository wordRepository,
    required ProgressLocalDataSource progressLocal,
    required ProgressRemoteDataSource progressRemote,
    required AuthRepository authRepository,
  }) : _wordRepository = wordRepository,
       _progressLocal = progressLocal,
       _progressRemote = progressRemote,
       _authRepository = authRepository,
       super(const WordDetailInitial()) {
    unawaited(_initTts());
  }

  final WordRepository _wordRepository;
  final ProgressLocalDataSource _progressLocal;
  final ProgressRemoteDataSource _progressRemote;
  final AuthRepository _authRepository;

  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;

  // ─── TTS init ─────────────────────────────────────────────────────────────

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(AppConstants.ttsDefaultRate);
      await _tts.setVolume(1);
      await _tts.setPitch(1);
      _ttsReady = true;
    } on Object catch (e, st) {
      debugPrint('[WordDetailCubit] TTS init: $e\n$st');
    }
  }

  @override
  Future<void> close() async {
    await _tts.stop();
    return super.close();
  }

  // ─── Public API ───────────────────────────────────────────────────────────────

  Future<void> load(String wordId) async {
    emit(const WordDetailLoading());
    try {
      final word = await _wordRepository.getWordById(wordId);
      if (word == null) {
        if (!isClosed) emit(const WordDetailError('Слово не найдено'));
        return;
      }
      final isFavorite = await _isFavorite(word.id);
      final progress = await _loadProgress(word.id);
      if (!isClosed) {
        emit(
          WordDetailLoaded(
            word: word,
            isFavorite: isFavorite,
            progress: progress,
          ),
        );
      }
    } on Object catch (e, st) {
      debugPrint('[WordDetailCubit] load: $e\n$st');
      if (!isClosed) emit(WordDetailError(e.toString()));
    }
  }

  Future<void> toggleFavorite() async {
    final s = state;
    if (s is! WordDetailLoaded) return;
    final newValue = !s.isFavorite;
    emit(s.copyWith(isFavorite: newValue));
    try {
      final box = await _openFavoritesBox();
      if (newValue) {
        await box.put(s.word.id, true);
      } else {
        await box.delete(s.word.id);
      }
      unawaited(_syncFavorite(wordId: s.word.id, add: newValue));
    } on Object catch (e, st) {
      debugPrint('[WordDetailCubit] toggleFavorite: $e\n$st');
      if (!isClosed) emit(s);
    }
  }

  Future<void> playAudio() async {
    final s = state;
    if (s is! WordDetailLoaded || s.isPlaying) return;

    emit(s.copyWith(isPlaying: true));

    final completer = Completer<void>();
    _tts
      ..setCompletionHandler(() {
        if (!completer.isCompleted) completer.complete();
      })
      ..setErrorHandler((msg) {
        debugPrint('[WordDetailCubit] TTS error: $msg');
        if (!completer.isCompleted) completer.complete();
      });

    try {
      if (!_ttsReady) await _initTts();
      await _tts.speak(s.word.word);
      await completer.future;
    } on Object catch (e, st) {
      debugPrint('[WordDetailCubit] playAudio: $e\n$st');
    } finally {
      if (!isClosed) {
        final curr = state;
        if (curr is WordDetailLoaded) emit(curr.copyWith(isPlaying: false));
      }
    }
  }

  Future<void> applyAnswer({required bool knew}) async {
    final s = state;
    if (s is! WordDetailLoaded || s.isProcessingProgress) return;

    emit(s.copyWith(isProcessingProgress: true));
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(AppConstants.keyGuestMode) ?? false;
      final userId = _authRepository.currentUserId ?? 'guest';

      final easeFactor =
          (s.progress?['ease_factor'] as num?)?.toDouble() ??
          AppConstants.sm2DefaultEaseFactor;
      final repetitions = s.progress?['repetitions'] as int? ?? 0;

      final newProgress = _computeSm2(
        wordId: s.word.id,
        userId: userId,
        knew: knew,
        easeFactor: easeFactor,
        repetitions: repetitions,
      );

      await _progressLocal.saveProgressEntry(
        wordId: s.word.id,
        data: newProgress,
      );
      if (!isGuest) unawaited(_syncProgress(newProgress));

      if (!isClosed) {
        emit(
          WordDetailLoaded(
            word: s.word,
            isFavorite: s.isFavorite,
            progress: newProgress,
            lastAnswerKnew: knew,
          ),
        );
      }
    } on Object catch (e, st) {
      debugPrint('[WordDetailCubit] applyAnswer: $e\n$st');
      if (!isClosed) emit(s.copyWith(isProcessingProgress: false));
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  Future<Box<dynamic>> _openFavoritesBox() =>
      Hive.isBoxOpen(AppConstants.hiveBoxFavorites)
          ? Future.value(Hive.box<dynamic>(AppConstants.hiveBoxFavorites))
          : Hive.openBox<dynamic>(AppConstants.hiveBoxFavorites);

  Future<bool> _isFavorite(String wordId) async {
    try {
      final box = await _openFavoritesBox();
      return box.containsKey(wordId);
    } on Object catch (e, st) {
      debugPrint('[WordDetailCubit] _isFavorite: $e\n$st');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _loadProgress(String wordId) async {
    try {
      final progressBox = Hive.isBoxOpen(AppConstants.hiveBoxProgress)
          ? Hive.box<dynamic>(AppConstants.hiveBoxProgress)
          : await Hive.openBox<dynamic>(AppConstants.hiveBoxProgress);
      final local = progressBox.get(wordId);
      if (local is Map) return Map<String, dynamic>.from(local);

      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(AppConstants.keyGuestMode) ?? false;
      final userId = _authRepository.currentUserId;
      if (isGuest || userId == null) return null;

      final remote = await Supabase.instance.client
          .from(SupabaseConstants.tableUserWordProgress)
          .select(
            'word_id, ease_factor, repetitions, status, next_review_at, last_reviewed_at',
          )
          .eq('user_id', userId)
          .eq('word_id', wordId)
          .maybeSingle();
      return remote != null ? Map<String, dynamic>.from(remote) : null;
    } on Object catch (e, st) {
      debugPrint('[WordDetailCubit] _loadProgress: $e\n$st');
      return null;
    }
  }

  Future<void> _syncFavorite({
    required String wordId,
    required bool add,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(AppConstants.keyGuestMode) ?? false;
      final userId = _authRepository.currentUserId;
      if (isGuest || userId == null) return;
      if (add) {
        await Supabase.instance.client
            .from(SupabaseConstants.tableUserFavorites)
            .upsert({'user_id': userId, 'word_id': wordId});
      } else {
        await Supabase.instance.client
            .from(SupabaseConstants.tableUserFavorites)
            .delete()
            .eq('user_id', userId)
            .eq('word_id', wordId);
      }
    } on Object catch (e, st) {
      debugPrint('[WordDetailCubit] _syncFavorite: $e\n$st');
    }
  }

  Future<void> _syncProgress(Map<String, dynamic> data) async {
    try {
      await _progressRemote.upsertProgressEntry(data);
    } on Object catch (e, st) {
      debugPrint('[WordDetailCubit] _syncProgress: $e\n$st');
    }
  }

  Map<String, dynamic> _computeSm2({
    required String wordId,
    required String userId,
    required bool knew,
    required double easeFactor,
    required int repetitions,
  }) {
    final now = DateTime.now();
    if (!knew) {
      return {
        'word_id': wordId,
        'user_id': userId,
        'status': 'learning',
        'repetitions': 0,
        'ease_factor': (easeFactor - 0.2).clamp(
          AppConstants.sm2MinEaseFactor,
          double.infinity,
        ),
        'next_review_at': now.add(const Duration(hours: 1)).toIso8601String(),
        'last_reviewed_at': now.toIso8601String(),
      };
    }
    final newRepetitions = repetitions + 1;
    final interval = switch (newRepetitions) {
      1 => AppConstants.sm2FirstInterval,
      2 => AppConstants.sm2SecondInterval,
      _ => (easeFactor * (newRepetitions - 1)).round(),
    };
    return {
      'word_id': wordId,
      'user_id': userId,
      'status': interval >= 21 ? 'known' : 'learning',
      'repetitions': newRepetitions,
      'ease_factor': (easeFactor + 0.1).clamp(
        AppConstants.sm2MinEaseFactor,
        double.infinity,
      ),
      'next_review_at': now.add(Duration(days: interval)).toIso8601String(),
      'last_reviewed_at': now.toIso8601String(),
    };
  }
}
