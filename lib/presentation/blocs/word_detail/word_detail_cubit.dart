import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/data/datasources/local/progress_local_datasource.dart';
import 'package:til1m/data/datasources/remote/progress_remote_datasource.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/entities/word_progress.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/domain/repositories/word_repository.dart';
import 'package:til1m/domain/usecases/calculate_sm2.dart';

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

  static const _sm2 = CalculateSm2();

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
      final isFavorite = await _progressLocal.isFavorite(word.id);
      final progress = await _loadProgress(word.id);
      if (!isClosed) {
        emit(WordDetailLoaded(word: word, isFavorite: isFavorite, progress: progress));
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
      await _progressLocal.setFavorite(s.word.id, add: newValue);
      unawaited(_syncFavorite(wordId: s.word.id, add: newValue));
    } on Object catch (e, st) {
      debugPrint('[WordDetailCubit] toggleFavorite: $e\n$st');
      if (!isClosed) emit(s); // revert optimistic update
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
      final current = s.progress ?? WordProgress(wordId: s.word.id);
      final result = _sm2.calculate(current: current, isCorrect: knew);
      final updated = result.updatedProgress;

      await _progressLocal.saveProgress(updated);
      unawaited(_syncProgress(updated));

      if (!isClosed) {
        emit(
          WordDetailLoaded(
            word: s.word,
            isFavorite: s.isFavorite,
            progress: updated,
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

  /// Loads progress: local cache first, remote fallback for authenticated users.
  Future<WordProgress?> _loadProgress(String wordId) async {
    final local = await _progressLocal.getProgressForWord(wordId);
    if (local != null) return local;

    if (_authRepository.currentUserId == null) {
      return null;
    }

    try {
      return await _progressRemote.fetchProgressForWord(
        userId: _authRepository.currentUserId!,
        wordId: wordId,
      );
    } on Object catch (e, st) {
      debugPrint('[WordDetailCubit] _loadProgress remote: $e\n$st');
      return null;
    }
  }

  Future<void> _syncFavorite({
    required String wordId,
    required bool add,
  }) async {
    if (_authRepository.currentUserId == null) return;
    try {
      await _progressRemote.syncFavorite(
        userId: _authRepository.currentUserId!,
        wordId: wordId,
        add: add,
      );
    } on Object catch (e, st) {
      debugPrint('[WordDetailCubit] _syncFavorite: $e\n$st');
    }
  }

  Future<void> _syncProgress(WordProgress progress) async {
    if (_authRepository.currentUserId == null) return;
    try {
      await _progressRemote.syncProgress(
        progress,
        _authRepository.currentUserId!,
      );
    } on Object catch (e, st) {
      debugPrint('[WordDetailCubit] _syncProgress: $e\n$st');
    }
  }
}
