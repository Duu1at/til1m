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
  static const String keyStudyTimeFrom = 'study_time_from';
  static const String keyStudyTimeTo = 'study_time_to';
  static const String keyLanguageSelected = 'language_selected';
  static const String keyPendingAuth = 'pending_auth';

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

  // Spacing & Padding
  static const double paddingXS = 6;
  static const double paddingS = 8;
  static const double paddingM = 12;
  static const double paddingL = 16;
  static const double paddingXL = 20;
  static const double paddingXXL = 24;
  static const double paddingWide = 28;
  static const double paddingSection = 32;
  static const double paddingLarge = 40;
  static const double paddingHuge = 48;

  // Border Radius
  static const double radiusXS = 2;
  static const double radiusS = 6;
  static const double radiusM = 12;
  static const double radiusL = 14;
  static const double radiusXL = 16;
  static const double radiusXXL = 24;
  static const double radiusFull = 999;

  // Component Sizes
  static const double buttonHeight = 52;
  static const double buttonHeightS = 40;
  static const double iconBoxSize = 44;
  static const double iconBoxSizeS = 32;
  static const double logoBoxSize = 88;
  static const double bottomNavHeight = 64;
  static const double appBarHeight = 56;
  static const double cardElevation = 0;
  static const double dividerThickness = 1;

  // Animation Durations (milliseconds)
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);
  static const Duration durationPage = Duration(milliseconds: 300);
}
