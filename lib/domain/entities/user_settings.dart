import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:wordup/domain/entities/word.dart';

enum AppTheme { light, dark, system }

@immutable
final class UserSettings extends Equatable {
  const UserSettings({
    this.userId,
    this.dailyGoal = 5,
    this.englishLevel = WordLevel.a1,
    this.uiLanguage = UiLanguage.ru,
    this.reminderTime,
    this.theme = AppTheme.system,
  });

  final String? userId;
  final int dailyGoal;
  final WordLevel englishLevel;
  final UiLanguage uiLanguage;
  final String? reminderTime; // 'HH:mm' format
  final AppTheme theme;

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
  List<Object?> get props => [
    userId,
    dailyGoal,
    englishLevel,
    uiLanguage,
    reminderTime,
    theme,
  ];
}
