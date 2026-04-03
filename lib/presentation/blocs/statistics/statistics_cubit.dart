import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';

part 'statistics_state.dart';

class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit(this._repo) : super(const StatisticsInitial()) {
    unawaited(load());
    _authSub = _repo.authStateChanges.listen((_) => load());
  }

  final AuthRepository _repo;
  late final StreamSubscription<bool> _authSub;

  Future<void> load() async {
    emit(const StatisticsLoading());
    try {
      final box = Hive.isBoxOpen(AppConstants.hiveBoxProgress)
          ? Hive.box<dynamic>(AppConstants.hiveBoxProgress)
          : await Hive.openBox<dynamic>(AppConstants.hiveBoxProgress);

      var knownCount = 0;
      var learningCount = 0;
      var todayReviewed = 0;
      final today = DateTime.now();

      for (final value in box.values) {
        if (value is! Map) continue;
        final status = value['status'] as String? ?? '';
        if (status == 'known') knownCount++;
        if (status == 'learning') learningCount++;

        final lastStr = value['last_reviewed_at'] as String?;
        if (lastStr != null) {
          final dt = DateTime.tryParse(lastStr);
          if (dt != null &&
              dt.year == today.year &&
              dt.month == today.month &&
              dt.day == today.day) {
            todayReviewed++;
          }
        }
      }

      if (!isClosed) {
        emit(
          StatisticsLoaded(
            StatisticsData(
              knownCount: knownCount,
              learningCount: learningCount,
              todayReviewed: todayReviewed,
              streakDays: 0,
            ),
          ),
        );
      }
    } on Object catch (e, st) {
      debugPrint('[Statistics] load error: $e\n$st');
      if (!isClosed) emit(const StatisticsLoaded(StatisticsData.empty));
    }
  }

  @override
  Future<void> close() async {
    await _authSub.cancel();
    return super.close();
  }
}
