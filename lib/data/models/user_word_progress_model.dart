import 'package:til1m/domain/entities/user_progress.dart';

final class UserWordProgressModel {
  const UserWordProgressModel({
    required this.id,
    required this.userId,
    required this.wordId,
    this.status = WordStatus.newWord,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.nextReviewAt,
    this.lastReviewedAt,
  });

  factory UserWordProgressModel.fromEntity(UserWordProgress entity) {
    return UserWordProgressModel(
      id: entity.id,
      userId: entity.userId,
      wordId: entity.wordId,
      status: entity.status,
      easeFactor: entity.easeFactor,
      repetitions: entity.repetitions,
      nextReviewAt: entity.nextReviewAt,
      lastReviewedAt: entity.lastReviewedAt,
    );
  }

  factory UserWordProgressModel.fromJson(Map<String, dynamic> json) {
    return UserWordProgressModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      wordId: json['word_id'] as String,
      status: _parseStatus(json['status'] as String?),
      easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
      repetitions: json['repetitions'] as int? ?? 0,
      nextReviewAt: json['next_review_at'] != null
          ? DateTime.tryParse(json['next_review_at'] as String)
          : null,
      lastReviewedAt: json['last_reviewed_at'] != null
          ? DateTime.tryParse(json['last_reviewed_at'] as String)
          : null,
    );
  }

  factory UserWordProgressModel.fromHive(Map<dynamic, dynamic> map) {
    final json = Map<String, dynamic>.from(map);
    return UserWordProgressModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      wordId: json['word_id'] as String,
      status: _parseStatus(json['status'] as String?),
      easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
      repetitions: json['repetitions'] as int? ?? 0,
      nextReviewAt: json['next_review_at'] != null
          ? DateTime.tryParse(json['next_review_at'] as String)
          : null,
      lastReviewedAt: json['last_reviewed_at'] != null
          ? DateTime.tryParse(json['last_reviewed_at'] as String)
          : null,
    );
  }

  final String id;
  final String userId;
  final String wordId;
  final WordStatus status;
  final double easeFactor;
  final int repetitions;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'word_id': wordId,
    'status': _statusToString(status),
    'ease_factor': easeFactor,
    'repetitions': repetitions,
    'next_review_at': nextReviewAt?.toIso8601String(),
    'last_reviewed_at': lastReviewedAt?.toIso8601String(),
  };

  Map<String, dynamic> toHive() => {
    'word_id': wordId,
    'status': _statusToString(status),
    'ease_factor': easeFactor,
    'repetitions': repetitions,
    'next_review_at': nextReviewAt?.toIso8601String(),
    'last_reviewed_at': lastReviewedAt?.toIso8601String(),
  };

  UserWordProgress toEntity() => UserWordProgress(
    id: id,
    userId: userId,
    wordId: wordId,
    status: status,
    easeFactor: easeFactor,
    repetitions: repetitions,
    nextReviewAt: nextReviewAt,
    lastReviewedAt: lastReviewedAt,
  );

  static WordStatus _parseStatus(String? value) => switch (value) {
    'learning' => WordStatus.learning,
    'known' => WordStatus.known,
    _ => WordStatus.newWord,
  };

  static String _statusToString(WordStatus status) => switch (status) {
    WordStatus.newWord => 'new',
    WordStatus.learning => 'learning',
    WordStatus.known => 'known',
  };
}
