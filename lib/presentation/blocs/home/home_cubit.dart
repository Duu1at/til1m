import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/data/datasources/local/progress_local_datasource.dart';
import 'package:til1m/data/datasources/remote/progress_remote_datasource.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required AuthRepository authRepo,
    required ProgressLocalDataSource localDataSource,
    required ProgressRemoteDataSource remoteDataSource,
  })  : _authRepo = authRepo,
        _local = localDataSource,
        _remote = remoteDataSource,
        super(const HomeInitial()) {
    unawaited(load());
    _authSub = authRepo.authStateChanges.listen((_) => load());
  }

  final AuthRepository _authRepo;
  final ProgressLocalDataSource _local;
  final ProgressRemoteDataSource _remote;
  late final StreamSubscription<bool> _authSub;

  Future<void> load() async {
    emit(const HomeLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyGoal = prefs.getInt(AppConstants.keyDailyGoal) ?? 5;
      final userLevel = prefs.getString(AppConstants.keyUserLevel) ?? 'a1';
      final isGuest = prefs.getBool(AppConstants.keyGuestMode) ?? false;

      Map<String, int> stats;
      if (!isGuest && _authRepo.isAuthenticated) {
        final userId = _authRepo.currentUserId!;
        try {
          stats = await _remote.fetchProgressStats(userId);
        } on Object catch (e, st) {
          debugPrint('[Home] remote failed, falling back to local: $e\n$st');
          stats = await _local.fetchProgressStats();
        }
      } else {
        stats = await _local.fetchProgressStats();
      }

      if (!isClosed) {
        emit(
          HomeLoaded(
            HomeData(
              dailyGoal: dailyGoal,
              todayReviewed: stats['today_reviewed'] ?? 0,
              knownCount: stats['known'] ?? 0,
              learningCount: stats['learning'] ?? 0,
              dueCount: stats['due'] ?? 0,
              streakDays: 0,
              userLevel: userLevel,
              isGuest: isGuest,
            ),
          ),
        );
      }
    } on Object catch (e, st) {
      debugPrint('[Home] load error: $e\n$st');
      if (!isClosed) emit(const HomeLoaded(HomeData.empty));
    }
  }

  @override
  Future<void> close() async {
    await _authSub.cancel();
    return super.close();
  }
}
