import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/supabase_constants.dart';
import 'package:til1m/core/di/service_locator.dart';
import 'package:til1m/core/network/connectivity_service.dart';
import 'package:til1m/core/router/app_router.dart';
import 'package:til1m/data/datasources/sync/progress_sync_service.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/presentation/blocs/auth/auth_cubit.dart';
import 'package:til1m/presentation/blocs/settings/settings_cubit.dart';
import 'package:til1m/presentation/blocs/statistics/statistics_cubit.dart';
import 'package:til1m/services/widget_service/widget_background_service.dart';
import 'package:til1m/services/widget_service/widget_service.dart';
import 'package:til1m/til1m_app.dart';

/// Router reference set once the widget tree is built.
/// Nullable so the deep-link handler can bail early if the app is not yet ready.
GoRouter? _appRouter;

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

  // Initialise home_widget App Group (required on iOS).
  await WidgetService.setAppGroupId();

  // Register WorkManager periodic task for background widget refresh (Android).
  unawaited(const WidgetBackgroundService().register());

  final connectivity = sl<ConnectivityService>();

  connectivity.onlineStream
      .where((online) => online)
      .take(1)
      .listen((_) => _flushPendingSync());
  if (connectivity.isOnline) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _flushPendingSync());
  }

  // Listen for deep links fired by widget taps.
  HomeWidget.widgetClicked.listen(_handleWidgetDeepLink);

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
      child: Til1mApp(
        authCubit: authCubit,
        settingsCubit: settingsCubit,
        statisticsCubit: statisticsCubit,
        initialThemeMode: initialThemeMode,
        onRouterCreated: (router) => _appRouter = router,
      ),
    ),
  );
}

void _handleWidgetDeepLink(Uri? uri) {
  if (uri == null) return;
  final router = _appRouter;
  if (router == null) return;

  // Guard: if the navigator is not yet mounted (e.g. widget deep link fires
  // before runApp completes), defer until the next frame.
  final ctx = router.routerDelegate.navigatorKey.currentContext;
  if (ctx == null) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _handleWidgetDeepLink(uri),
    );
    return;
  }

  switch (uri.host) {
    // Both 'word' and 'audio' open word detail.
    // Audio auto-play is deferred to a future iteration (WordDetailCubit).
    case 'word':
    case 'audio':
      final wordId = uri.queryParameters['id'];
      if (wordId != null && wordId.isNotEmpty) {
        router.go('/word/$wordId');
      }
    case 'home':
      router.go(AppRoutes.home);
    case 'dictionary':
      router.go(AppRoutes.dictionary);
    case 'review':
      router.go('${AppRoutes.flashcards}?mode=review');
    default:
      router.go(AppRoutes.home);
  }
}

Future<void> _flushPendingSync() async {
  final authRepo = sl<AuthRepository>();
  final userId = authRepo.currentUserId;
  if (userId == null) return;
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
