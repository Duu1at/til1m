import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/supabase_constants.dart';

final class MigrateGuestProgress {
  const MigrateGuestProgress(this._client);

  final SupabaseClient _client;

  Future<void> call(String newUserId, {BuildContext? context}) async {
    final box = await _openBox();

    if (box.isEmpty) {
      debugPrint('[MigrateGuestProgress] nothing to migrate');
      return;
    }

    try {
      final localEntries = _readLocalEntries(box, newUserId);
      final wordIds = localEntries.map((e) => e['word_id'] as String).toList();

      // Fetch existing server records to resolve conflicts.
      final serverRows = await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select('word_id, repetitions, last_reviewed_at')
          .eq('user_id', newUserId)
          .inFilter('word_id', wordIds);

      final serverMap = <String, Map<String, dynamic>>{
        for (final row in serverRows) row['word_id'] as String: row,
      };

      final toUpsert = <Map<String, dynamic>>[];
      for (final entry in localEntries) {
        final wordId = entry['word_id'] as String;
        final server = serverMap[wordId];

        if (server == null) {
          toUpsert.add(entry);
          continue;
        }

        final localReps = entry['repetitions'] as int? ?? 0;
        final serverReps = server['repetitions'] as int? ?? 0;

        if (localReps > serverReps) {
          toUpsert.add(entry);
        } else if (localReps == serverReps) {
          final localDate = _parseDate(entry['last_reviewed_at'] as String?);
          final serverDate = _parseDate(server['last_reviewed_at'] as String?);
          if (localDate.isAfter(serverDate)) toUpsert.add(entry);
        }
      }

      if (toUpsert.isNotEmpty) {
        await _client
            .from(SupabaseConstants.tableUserWordProgress)
            .upsert(toUpsert, onConflict: 'user_id,word_id');
      }

      await box.clear();

      debugPrint(
        '[MigrateGuestProgress] done → upserted=${toUpsert.length}, '
        'skipped=${localEntries.length - toUpsert.length}',
      );

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Прогресс перенесён в аккаунт!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on Object catch (e, st) {
      debugPrint('[MigrateGuestProgress] error: $e\n$st');
      rethrow;
    }
  }

  Future<Box<dynamic>> _openBox() async =>
      Hive.isBoxOpen(AppConstants.hiveBoxProgress)
      ? Hive.box<dynamic>(AppConstants.hiveBoxProgress)
      : Hive.openBox<dynamic>(AppConstants.hiveBoxProgress);

  List<Map<String, dynamic>> _readLocalEntries(
    Box<dynamic> box,
    String userId,
  ) {
    final entries = <Map<String, dynamic>>[];
    for (final entry in box.toMap().entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final raw = Map<String, dynamic>.from(value);
      final wordId = raw['word_id'] as String? ?? entry.key as String? ?? '';
      if (wordId.isEmpty) continue;
      entries.add({
        'user_id': userId,
        'word_id': wordId,
        'status': raw['status'] as String? ?? 'new',
        'ease_factor': (raw['ease_factor'] as num?)?.toDouble() ?? 2.5,
        'repetitions': raw['repetitions'] as int? ?? 0,
        'next_review_at': raw['next_review_at'] as String?,
        'last_reviewed_at': raw['last_reviewed_at'] as String?,
      });
    }
    return entries;
  }

  static DateTime _parseDate(String? value) => value != null
      ? DateTime.tryParse(value) ?? DateTime(1970)
      : DateTime(1970);
}
