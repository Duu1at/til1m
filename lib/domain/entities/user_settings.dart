import 'package:equatable/equatable.dart';
import 'word.dart';

enum AppTheme { light, dark, system }

class UserSettings extends Equatable {
  final String? userId;
  final int dailyGoal;
  final WordLevel englishLevel;
  final UiLanguage uiLanguage;
  final String? reminderTime; // "HH:mm" format
  final AppTheme theme;

  const UserSettings({
    this.userId,
    this.dailyGoal = 5,
    this.englishLevel = WordLevel.a1,
    this.uiLanguage = UiLanguage.ru,
    this.reminderTime,
    this.theme = AppTheme.system,
  });

  UserSettings copyWith({
    String? userId,
    int? dailyGoal,
    WordLevel? englishLevel,
    UiLanguage? uiLanguage,
    String? reminderTime,
    AppTheme? theme,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      englishLevel: englishLevel ?? this.englishLevel,
      uiLanguage: uiLanguage ?? this.uiLanguage,
      reminderTime: reminderTime ?? this.reminderTime,
      theme: theme ?? this.theme,
    );
  }

  @override
  List<Object?> get props => [userId, dailyGoal, englishLevel, uiLanguage, reminderTime, theme];
}
