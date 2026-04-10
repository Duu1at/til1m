import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/supabase_constants.dart';
import 'package:til1m/core/di/service_locator.dart';
import 'package:til1m/core/network/connectivity_service.dart';
import 'package:til1m/data/datasources/sync/progress_sync_service.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/presentation/blocs/auth/auth_cubit.dart';
import 'package:til1m/presentation/blocs/settings/settings_cubit.dart';
import 'package:til1m/presentation/blocs/statistics/statistics_cubit.dart';
import 'package:til1m/til1im_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Hive.initFlutter();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
    debug: true,
  );

  setupServiceLocator();

  final connectivity = sl<ConnectivityService>();

  connectivity.onlineStream
      .where((online) => online)
      .take(1)
      .listen((_) => _flushPendingSync());
  if (connectivity.isOnline) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _flushPendingSync());
  }

  final initialThemeMode = await _readSavedThemeMode();

  final repo = sl<AuthRepository>();
  final authCubit = AuthCubit(repo);
  final settingsCubit = SettingsCubit(repo);
  final statisticsCubit = StatisticsCubit(repo);

  runApp(
    EasyLocalization(
      supportedLocales: AppConstants.supportedLocales,
      path: AppConstants.translationsPath,
      fallbackLocale: AppConstants.fallbackLocale,
      child: Til1imApp(
        authCubit: authCubit,
        settingsCubit: settingsCubit,
        statisticsCubit: statisticsCubit,
        initialThemeMode: initialThemeMode,
      ),
    ),
  );
}

Future<void> _flushPendingSync() async {
  final authRepo = sl<AuthRepository>();
  final userId = authRepo.currentUserId;
  if (userId == null || authRepo.isGuest) return;
  final result = await sl<ProgressSyncService>().flush(userId);
  if (result.syncedCount > 0) {
    debugPrint('[main] Startup sync: ${result.syncedCount} entries uploaded');
  }
}

Future<ThemeMode> _readSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  return switch (prefs.getString(AppConstants.keyTheme)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
