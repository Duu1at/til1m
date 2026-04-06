import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:til1m/core/constants/app_constants.dart';
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
  WordStatusFilter _statusFilter = WordStatusFilter.all;
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
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(AppConstants.keyGuestMode) ?? false;
      final userId = _authRepo.currentUserId;
      final isAuth = !isGuest && userId != null;

      if (isAuth) {
        await _prepareRemoteStatusFilter(userId: userId);
        await _loadRemotePage(userId: userId, append: false);
      } else {
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
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(AppConstants.keyGuestMode) ?? false;
      final userId = _authRepo.currentUserId;
      final isAuth = !isGuest && userId != null;

      if (isAuth) {
        await _loadRemotePage(userId: userId, append: true);
      } else {
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

  void onStatusFilterChanged(WordStatusFilter filter) {
    if (_statusFilter == filter) return;
    _statusFilter = filter;
    unawaited(load());
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

  Future<void> _prepareRemoteStatusFilter({required String userId}) async {
    switch (_statusFilter) {
      case WordStatusFilter.all:
        break;
      case WordStatusFilter.newWord:
        _cachedExcludeIds = await _wordRemote.fetchProgressIds(userId: userId);
        _cachedFixedStatus = WordStatus.newWord;
      case WordStatusFilter.learning:
        _cachedInIds = await _wordRemote.fetchProgressIds(
          userId: userId,
          status: 'learning',
        );
        _cachedFixedStatus = WordStatus.learning;
      case WordStatusFilter.known:
        _cachedInIds = await _wordRemote.fetchProgressIds(
          userId: userId,
          status: 'known',
        );
        _cachedFixedStatus = WordStatus.known;
    }
  }

  Future<void> _loadRemotePage({
    required String userId,
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
    if (_cachedFixedStatus == null && result.words.isNotEmpty) {
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
            statusFilter: _statusFilter,
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
      statusFilter: _statusFilterString,
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
            statusFilter: _statusFilter,
            levelFilter: _levelFilter,
            sort: _sort,
          ),
        );
      }
    }
  }

  String get _statusFilterString => switch (_statusFilter) {
    WordStatusFilter.all => 'all',
    WordStatusFilter.newWord => 'newWord',
    WordStatusFilter.learning => 'learning',
    WordStatusFilter.known => 'known',
  };

  WordStatus _parseStatus(String? s) => switch (s) {
    'learning' => WordStatus.learning,
    'known' => WordStatus.known,
    _ => WordStatus.newWord,
  };
}
