import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:til1m/core/constants/app_constants.dart';

class ProgressLocalDataSource {
  Future<Map<String, int>> fetchProgressStats() async {
    try {
      final box = Hive.isBoxOpen(AppConstants.hiveBoxProgress)
          ? Hive.box<dynamic>(AppConstants.hiveBoxProgress)
          : await Hive.openBox<dynamic>(AppConstants.hiveBoxProgress);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      var knownCount = 0;
      var learningCount = 0;
      var todayReviewed = 0;
      var dueCount = 0;

      for (final value in box.values) {
        if (value is! Map) continue;
        final status = value['status'] as String? ?? '';
        if (status == 'known') knownCount++;
        if (status == 'learning') learningCount++;

        final lastStr = value['last_reviewed_at'] as String?;
        if (lastStr != null) {
          final dt = DateTime.tryParse(lastStr);
          if (dt != null && dt.isAfter(todayStart)) todayReviewed++;
        }

        final nextStr = value['next_review_at'] as String?;
        if (nextStr != null) {
          final dt = DateTime.tryParse(nextStr);
          if (dt != null && !dt.isAfter(now)) dueCount++;
        }
      }

      return {
        'known': knownCount,
        'learning': learningCount,
        'today_reviewed': todayReviewed,
        'due': dueCount,
      };
    } on Object catch (e, st) {
      debugPrint('[ProgressLocal] fetchProgressStats error: $e\n$st');
      return {'known': 0, 'learning': 0, 'today_reviewed': 0, 'due': 0};
    }
  }
}
