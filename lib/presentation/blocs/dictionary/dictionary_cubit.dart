import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/data/datasources/local/word_local_datasource.dart';
import 'package:til1m/data/datasources/remote/word_remote_datasource.dart';
import 'package:til1m/domain/entities/user_progress.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';

part 'dictionary_state.dart';

class DictionaryCubit extends Cubit<DictionaryState> {
  DictionaryCubit({
    required AuthRepository authRepo,
    required WordRemoteDataSource wordRemote,
    required WordLocalDataSource wordLocal,
  }) : _authRepo = authRepo,
       _wordRemote = wordRemote,
       _wordLocal = wordLocal,
       super(const DictionaryInitial()) {
    unawaited(load());
  }

  final AuthRepository _authRepo;
  final WordRemoteDataSource _wordRemote;
  final WordLocalDataSource _wordLocal;

  String _query = '';
  WordLevel? _levelFilter;
  DictionarySort _sort = DictionarySort.alphabetical;

  int _page = 0;
  static const _pageSize = 20;

  List<String>? _cachedInIds;
  List<String>? _cachedExcludeIds;
  WordStatus? _cachedFixedStatus;

  Timer? _debounce;

  Future<void> load() async {
    _page = 0;
    _cachedInIds = null;
    _cachedExcludeIds = null;
    _cachedFixedStatus = null;

    final current = state;
    if (current is DictionaryLoaded) {
      emit(current.copyWith(isFiltering: true, isLoadingMore: false));
    } else {
      emit(const DictionaryLoading());
    }

    try {
      final userId = _authRepo.currentUserId;

      try {
        await _loadRemotePage(userId: userId, append: false);
      } on Object catch (e, st) {
        debugPrint(
          '[Dictionary] remote failed, falling back to local: $e\n$st',
        );
        await _loadLocalPage(append: false);
      }
    } on Object catch (e, st) {
      debugPrint('[Dictionary] load error: $e\n$st');
      if (!isClosed) emit(const DictionaryLoaded.empty());
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! DictionaryLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    _page++;

    try {
      final userId = _authRepo.currentUserId;

      try {
        await _loadRemotePage(userId: userId, append: true);
      } on Object catch (e, st) {
        debugPrint(
          '[Dictionary] remote loadMore failed, falling back to local: $e\n$st',
        );
        await _loadLocalPage(append: true);
      }
    } on Object catch (e, st) {
      debugPrint('[Dictionary] loadMore error: $e\n$st');
      final s = state;
      if (!isClosed && s is DictionaryLoaded) {
        emit(s.copyWith(isLoadingMore: false));
      }
    }
  }

  void onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _query = q;
      unawaited(load());
    });
  }

  void onLevelFilterChanged(WordLevel? level) {
    if (_levelFilter == level) return;
    _levelFilter = level;
    unawaited(load());
  }

  void onSortChanged(DictionarySort sort) {
    if (_sort == sort) return;
    _sort = sort;
    unawaited(load());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> _loadRemotePage({
    required String? userId,
    required bool append,
  }) async {
    if (_cachedInIds != null && _cachedInIds!.isEmpty) {
      if (!isClosed) {
        if (append) {
          final s = state as DictionaryLoaded;
          emit(s.copyWith(isLoadingMore: false, hasMore: false));
        } else {
          emit(const DictionaryLoaded.empty());
        }
      }
      return;
    }

    final result = await _wordRemote.fetchPage(
      offset: _page * _pageSize,
      limit: _pageSize + 1,
      searchQuery: _query.isEmpty ? null : _query,
      level: _levelFilter,
      inIds: _cachedInIds,
      excludeIds: (_cachedExcludeIds?.isEmpty ?? true)
          ? null
          : _cachedExcludeIds,
      sortByLevel: _sort == DictionarySort.byLevel,
    );

    var statusMap = <String, String>{};
    if (userId != null &&
        _cachedFixedStatus == null &&
        result.words.isNotEmpty) {
      try {
        statusMap = await _wordRemote.fetchStatusMap(
          userId: userId,
          wordIds: result.words.map((w) => w.id).toList(),
        );
      } on Object catch (e, st) {
        debugPrint('[Dictionary] fetchStatusMap error (non-fatal): $e\n$st');
      }
    }

    final pageWords = result.words.take(_pageSize).toList();
    final newItems = pageWords.map((w) {
      final status = _cachedFixedStatus ?? _parseStatus(statusMap[w.id]);
      return WordWithStatus(word: w, status: status);
    }).toList();

    if (!isClosed) {
      if (append) {
        final s = state as DictionaryLoaded;
        emit(
          s.copyWith(
            words: [...s.words, ...newItems],
            hasMore: result.words.length > _pageSize,
            isLoadingMore: false,
          ),
        );
      } else {
        emit(
          DictionaryLoaded(
            words: newItems,
            hasMore: result.words.length > _pageSize,
            isLoadingMore: false,
            query: _query,
            levelFilter: _levelFilter,
            sort: _sort,
          ),
        );
      }
    }
  }

  Future<void> _loadLocalPage({required bool append}) async {
    final result = await _wordLocal.fetchPage(
      offset: _page * _pageSize,
      limit: _pageSize + 1,
      searchQuery: _query.isEmpty ? null : _query,
      level: _levelFilter,
      sortByLevel: _sort == DictionarySort.byLevel,
    );

    final pageWords = result.words.take(_pageSize).toList();
    final newItems = pageWords
        .map(
          (w) => WordWithStatus(
            word: w,
            status: _parseStatus(result.statusMap[w.id]),
          ),
        )
        .toList();

    if (!isClosed) {
      if (append) {
        final s = state as DictionaryLoaded;
        emit(
          s.copyWith(
            words: [...s.words, ...newItems],
            hasMore: result.words.length > _pageSize,
            isLoadingMore: false,
          ),
        );
      } else {
        emit(
          DictionaryLoaded(
            words: newItems,
            hasMore: result.words.length > _pageSize,
            isLoadingMore: false,
            query: _query,
            levelFilter: _levelFilter,
            sort: _sort,
          ),
        );
      }
    }
  }

  WordStatus _parseStatus(String? s) => switch (s) {
    'learning' => WordStatus.learning,
    'known' => WordStatus.known,
    _ => WordStatus.newWord,
  };
}
