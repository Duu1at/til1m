import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/constants/supabase_constants.dart';

class ProgressRemoteDataSource {
  ProgressRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, int>> fetchProgressStats(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select('status, last_reviewed_at, next_review_at')
          .eq('user_id', userId);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      var knownCount = 0;
      var learningCount = 0;
      var todayReviewed = 0;
      var dueCount = 0;

      for (final row in data) {
        final status = row['status'] as String? ?? '';
        if (status == 'known') knownCount++;
        if (status == 'learning') learningCount++;

        final lastStr = row['last_reviewed_at'] as String?;
        if (lastStr != null) {
          final dt = DateTime.tryParse(lastStr);
          if (dt != null && dt.isAfter(todayStart)) todayReviewed++;
        }

        final nextStr = row['next_review_at'] as String?;
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
      debugPrint('[ProgressRemote] fetchProgressStats error: $e\n$st');
      rethrow;
    }
  }
}
