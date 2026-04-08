part of 'dictionary_cubit.dart';

enum WordStatusFilter { all, newWord, learning, known }

enum DictionarySort { alphabetical, byLevel }

final class WordWithStatus extends Equatable {
  const WordWithStatus({required this.word, required this.status});

  final Word word;
  final WordStatus status;

  @override
  List<Object?> get props => [word.id, status];
}

sealed class DictionaryState extends Equatable {
  const DictionaryState();
}

final class DictionaryInitial extends DictionaryState {
  const DictionaryInitial();
  @override
  List<Object?> get props => [];
}

final class DictionaryLoading extends DictionaryState {
  const DictionaryLoading();
  @override
  List<Object?> get props => [];
}

final class DictionaryLoaded extends DictionaryState {
  const DictionaryLoaded({
    required this.words,
    required this.hasMore,
    required this.isLoadingMore,
    required this.query,
    required this.sort,
    this.levelFilter,
    this.isFiltering = false,
  });

  const DictionaryLoaded.empty()
    : words = const [],
      hasMore = false,
      isLoadingMore = false,
      isFiltering = false,
      query = '',
      sort = DictionarySort.alphabetical,
      levelFilter = null;

  final List<WordWithStatus> words;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isFiltering;
  final String query;
  final WordLevel? levelFilter;
  final DictionarySort sort;

  DictionaryLoaded copyWith({
    List<WordWithStatus>? words,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isFiltering,
    String? query,
    WordStatusFilter? statusFilter,
    WordLevel? levelFilter,
    DictionarySort? sort,
  }) => DictionaryLoaded(
    words: words ?? this.words,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isFiltering: isFiltering ?? this.isFiltering,
    query: query ?? this.query,
    levelFilter: levelFilter ?? this.levelFilter,
    sort: sort ?? this.sort,
  );

  @override
  List<Object?> get props => [
    words,
    hasMore,
    isLoadingMore,
    isFiltering,
    query,
    levelFilter,
    sort,
  ];
}
