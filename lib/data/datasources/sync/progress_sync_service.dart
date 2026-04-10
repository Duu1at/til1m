import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/supabase_constants.dart';
import 'package:til1m/domain/entities/user_progress.dart';

/// Result returned by [ProgressSyncService.flush].
enum SyncOutcome { success, partialSuccess, noData, error }

final class SyncResult {
  const SyncResult({
    required this.outcome,
    required this.syncedCount,
    this.skippedCount = 0,
    this.errorMessage,
  });

  final SyncOutcome outcome;
  final int syncedCount;
  final int skippedCount;
  final String? errorMessage;

  bool get isSuccess => outcome == SyncOutcome.success;
  bool get hasData => syncedCount + skippedCount > 0;
}

/// Manages the `pending_sync` Hive box: queues offline progress writes and
/// flushes them to Supabase when the device comes back online.
///
/// Conflict rule: **server wins**.
/// If Supabase's `last_reviewed_at` is newer than the queued entry's
/// `last_reviewed_at`, the server record is not overwritten.
class ProgressSyncService {
  const ProgressSyncService(this._client);

  final SupabaseClient _client;

  // ─── Box helpers ─────────────────────────────────────────────────────────────

  Future<Box<dynamic>> _box() async =>
      Hive.isBoxOpen(AppConstants.hiveBoxPendingSync)
          ? Hive.box(AppConstants.hiveBoxPendingSync)
          : Hive.openBox(AppConstants.hiveBoxPendingSync);

  // ─── Write ────────────────────────────────────────────────────────────────────

  /// Queues [progress] for later upload.
  ///
  /// Uses `"${userId}_${wordId}"` as the key so repeated offline answers to the
  /// same word overwrite the previous pending entry (last-write-wins locally).
  Future<void> addPending(UserWordProgress progress) async {
    try {
      final box = await _box();
      final key = '${progress.userId}_${progress.wordId}';
      await box.put(key, {
        'word_id': progress.wordId,
        'user_id': progress.userId,
        'status': _statusStr(progress.status),
        'ease_factor': progress.easeFactor,
        'repetitions': progress.repetitions,
        'next_review_at': progress.nextReviewAt?.toIso8601String(),
        'last_reviewed_at': progress.lastReviewedAt?.toIso8601String(),
      });
    } on Object catch (e, st) {
      debugPrint('[ProgressSyncService] addPending error: $e\n$st');
    }
  }

  /// Removes the pending entry for [wordId] (called after a successful online
  /// write for the same word).
  Future<void> removePending({
    required String userId,
    required String wordId,
  }) async {
    try {
      final box = await _box();
      await box.delete('${userId}_$wordId');
    } on Object catch (e, st) {
      debugPrint('[ProgressSyncService] removePending error: $e\n$st');
    }
  }

  /// Returns the number of entries waiting to be synced.
  Future<int> pendingCount() async {
    try {
      final box = await _box();
      return box.length;
    } on Object {
      return 0;
    }
  }

  // ─── Flush ────────────────────────────────────────────────────────────────────

  /// Sends all pending entries to Supabase.
  ///
  /// Conflict resolution: fetches current server `last_reviewed_at` for each
  /// word. If the server record is newer, the pending entry is discarded
  /// (server wins). Otherwise the pending entry is upserted.
  Future<SyncResult> flush(String userId) async {
    final box = await _box();
    final entries = box
        .toMap()
        .entries
        .where((e) {
          final v = e.value;
          return v is Map && (v['user_id'] as String?) == userId;
        })
        .toList();

    if (entries.isEmpty) {
      return const SyncResult(outcome: SyncOutcome.noData, syncedCount: 0);
    }

    try {
      final pendingWordIds =
          entries.map((e) => (e.value as Map)['word_id'] as String).toList();

      // Fetch server records to resolve conflicts.
      final serverRows = await _client
          .from(SupabaseConstants.tableUserWordProgress)
          .select('word_id, last_reviewed_at')
          .eq('user_id', userId)
          .inFilter('word_id', pendingWordIds);

      final serverDates = <String, DateTime>{
        for (final row in serverRows)
          row['word_id'] as String: row['last_reviewed_at'] != null
              ? DateTime.parse(row['last_reviewed_at'] as String)
              : DateTime(1970),
      };

      // Partition into upsert candidates and server-wins skips.
      final toUpsert = <Map<String, dynamic>>[];
      var skipped = 0;

      for (final entry in entries) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        final wordId = data['word_id'] as String;
        final localDateStr = data['last_reviewed_at'] as String?;
        final localDate = localDateStr != null
            ? DateTime.tryParse(localDateStr) ?? DateTime(1970)
            : DateTime(1970);
        final serverDate = serverDates[wordId] ?? DateTime(1970);

        if (serverDate.isAfter(localDate)) {
          // Server is newer → server wins, discard pending.
          skipped++;
        } else {
          toUpsert.add(data);
        }
      }

      if (toUpsert.isNotEmpty) {
        await _client
            .from(SupabaseConstants.tableUserWordProgress)
            .upsert(toUpsert, onConflict: 'user_id,word_id');
      }

      // Clear flushed entries.
      for (final entry in entries) {
        await box.delete(entry.key);
      }

      final synced = toUpsert.length;
      debugPrint(
        '[ProgressSyncService] flush: synced=$synced, skipped=$skipped',
      );

      return SyncResult(
        outcome: skipped > 0 ? SyncOutcome.partialSuccess : SyncOutcome.success,
        syncedCount: synced,
        skippedCount: skipped,
      );
    } on Object catch (e, st) {
      debugPrint('[ProgressSyncService] flush error: $e\n$st');
      return SyncResult(
        outcome: SyncOutcome.error,
        syncedCount: 0,
        errorMessage: e.toString(),
      );
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static String _statusStr(WordStatus status) => switch (status) {
    WordStatus.newWord => 'new',
    WordStatus.learning => 'learning',
    WordStatus.known => 'known',
  };
}
