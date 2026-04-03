part of 'statistics_cubit.dart';

final class StatisticsData extends Equatable {
  const StatisticsData({
    required this.knownCount,
    required this.learningCount,
    required this.todayReviewed,
    required this.streakDays,
  });

  final int knownCount;
  final int learningCount;
  final int todayReviewed;
  final int streakDays;

  static const empty = StatisticsData(
    knownCount: 0,
    learningCount: 0,
    todayReviewed: 0,
    streakDays: 0,
  );

  @override
  List<Object?> get props => [knownCount, learningCount, todayReviewed, streakDays];
}

sealed class StatisticsState extends Equatable {
  const StatisticsState();
}

final class StatisticsInitial extends StatisticsState {
  const StatisticsInitial();
  @override
  List<Object?> get props => [];
}

final class StatisticsLoading extends StatisticsState {
  const StatisticsLoading();
  @override
  List<Object?> get props => [];
}

final class StatisticsLoaded extends StatisticsState {
  const StatisticsLoaded(this.data);

  final StatisticsData data;

  @override
  List<Object?> get props => [data];
}
