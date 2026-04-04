part of 'home_cubit.dart';

final class HomeData extends Equatable {
  const HomeData({
    required this.dailyGoal,
    required this.todayReviewed,
    required this.knownCount,
    required this.learningCount,
    required this.dueCount,
    required this.streakDays,
    required this.userLevel,
    required this.isGuest,
  });

  final int dailyGoal;
  final int todayReviewed;
  final int knownCount;
  final int learningCount;
  final int dueCount;
  final int streakDays;
  final String userLevel;
  final bool isGuest;

  static const empty = HomeData(
    dailyGoal: 5,
    todayReviewed: 0,
    knownCount: 0,
    learningCount: 0,
    dueCount: 0,
    streakDays: 0,
    userLevel: 'a1',
    isGuest: false,
  );

  @override
  List<Object?> get props => [
        dailyGoal,
        todayReviewed,
        knownCount,
        learningCount,
        dueCount,
        streakDays,
        userLevel,
        isGuest,
      ];
}

sealed class HomeState extends Equatable {
  const HomeState();
}

final class HomeInitial extends HomeState {
  const HomeInitial();
  @override
  List<Object?> get props => [];
}

final class HomeLoading extends HomeState {
  const HomeLoading();
  @override
  List<Object?> get props => [];
}

final class HomeLoaded extends HomeState {
  const HomeLoaded(this.data);

  final HomeData data;

  @override
  List<Object?> get props => [data];
}
