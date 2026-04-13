import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/domain/entities/user_settings.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repo) : super(const SettingsInitial()) {
    unawaited(_load());
    _authSub = _repo.authStateChanges.listen((_) => _load());
  }

  final AuthRepository _repo;
  late final StreamSubscription<bool> _authSub;

  Future<void> _load() async {
    emit(const SettingsLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _repo.currentUserId;

      final base = userId != null
          ? (await _repo.getUserSettings(userId)) ?? const UserSettings()
          : const UserSettings();
      final savedTheme = AppTheme.values.firstWhere(
        (t) => t.name == (prefs.getString(AppConstants.keyTheme) ?? ''),
        orElse: () => base.theme,
      );
      final settings = base.copyWith(theme: savedTheme);

      // Mirror all settings to SharedPreferences so other cubits (HomeCubit,
      // FlashcardBloc) always read up-to-date values even before they call
      // their own load().
      await prefs.setInt(AppConstants.keyDailyGoal, settings.dailyGoal);
      await prefs.setString(AppConstants.keyUserLevel, settings.englishLevel.name);
      await prefs.setString(AppConstants.keyTheme, settings.theme.name);
      await prefs.setString(AppConstants.keyUiLanguage, settings.uiLanguage.name);
      if (settings.reminderTime != null) {
        await prefs.setString(AppConstants.keyReminderTime, settings.reminderTime!);
      }

      if (!isClosed) emit(SettingsLoaded(settings));
    } on Object catch (e, st) {
      debugPrint('[Settings] load error: $e\n$st');
      if (!isClosed) emit(const SettingsLoaded(UserSettings()));
    }
  }

  Future<void> updateDailyGoal(int goal) =>
      _update((s) => s.copyWith(dailyGoal: goal));

  Future<void> updateLevel(WordLevel level) =>
      _update((s) => s.copyWith(englishLevel: level));

  Future<void> updateLanguage(UiLanguage language) =>
      _update((s) => s.copyWith(uiLanguage: language));

  Future<void> updateTheme(AppTheme theme) =>
      _update((s) => s.copyWith(theme: theme));

  Future<void> updateReminderTime(String? time) => _update(
    (s) => UserSettings(
      userId: s.userId,
      dailyGoal: s.dailyGoal,
      englishLevel: s.englishLevel,
      uiLanguage: s.uiLanguage,
      reminderTime: time,
      theme: s.theme,
    ),
  );

  Future<void> _update(UserSettings Function(UserSettings) updater) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final updated = updater(current.settings);
    emit(SettingsLoaded(updated));
    try {
      // Persist settings locally so HomeCubit can read them without Supabase.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyTheme, updated.theme.name);
      await prefs.setInt(AppConstants.keyDailyGoal, updated.dailyGoal);
      await prefs.setString(AppConstants.keyUserLevel, updated.englishLevel.name);
      await prefs.setString(AppConstants.keyUiLanguage, updated.uiLanguage.name);
      if (updated.reminderTime != null) {
        await prefs.setString(AppConstants.keyReminderTime, updated.reminderTime!);
      } else {
        await prefs.remove(AppConstants.keyReminderTime);
      }

      final userId = _repo.currentUserId;
      if (userId != null) {
        await _repo.saveUserSettings(
          UserSettings(
            userId: userId,
            dailyGoal: updated.dailyGoal,
            englishLevel: updated.englishLevel,
            uiLanguage: updated.uiLanguage,
            reminderTime: updated.reminderTime,
            theme: updated.theme,
          ),
        );
      }
    } on Object catch (e, st) {
      debugPrint('[Settings] save error: $e\n$st');
    }
  }

  @override
  Future<void> close() async {
    await _authSub.cancel();
    return super.close();
  }
}
