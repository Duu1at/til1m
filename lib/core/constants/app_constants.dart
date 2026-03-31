import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'WordUp';

  // Localization
  static const String translationsPath = 'assets/translations';
  static const List<Locale> supportedLocales = [
    Locale('ru'),
    Locale('ky'),
  ];
  static const Locale fallbackLocale = Locale('ru');
  static const String appVersion = '1.0.0';

  // SharedPreferences keys
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyGuestMode = 'guest_mode';
  static const String keyUserLevel = 'user_level';
  static const String keyDailyGoal = 'daily_goal';
  static const String keyUiLanguage = 'ui_language';
  static const String keyReminderTime = 'reminder_time';

  // Hive box names
  static const String hiveBoxWords = 'words';
  static const String hiveBoxProgress = 'progress';
  static const String hiveBoxFavorites = 'favorites';
  static const String hiveBoxSettings = 'settings';

  // Widget
  static const String widgetName = 'WordUpWidget';
  static const String widgetGroupId = 'group.com.wordup.widget';

  // SM-2 defaults
  static const double sm2DefaultEaseFactor = 2.5;
  static const double sm2MinEaseFactor = 1.3;
  static const int sm2FirstInterval = 1;
  static const int sm2SecondInterval = 6;

  // Daily goal options
  static const List<int> dailyGoalOptions = [3, 5, 10];

  // Notification
  static const int notificationId = 1001;
  static const String notificationChannelId = 'wordup_daily';
  static const String notificationChannelName = 'Daily Reminder';
}
