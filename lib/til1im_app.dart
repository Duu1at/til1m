import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/router/app_router.dart';
import 'package:til1m/core/theme/app_theme.dart' as app_theme;
import 'package:til1m/domain/entities/user_settings.dart';
import 'package:til1m/presentation/blocs/auth/auth_cubit.dart';
import 'package:til1m/presentation/blocs/settings/settings_cubit.dart';
import 'package:til1m/presentation/blocs/statistics/statistics_cubit.dart';

class Til1imApp extends StatefulWidget {
  const Til1imApp({
    required this.authCubit,
    required this.settingsCubit,
    required this.statisticsCubit,
    required this.initialThemeMode,
    super.key,
  });

  final AuthCubit authCubit;
  final SettingsCubit settingsCubit;
  final StatisticsCubit statisticsCubit;
  final ThemeMode initialThemeMode;

  @override
  State<Til1imApp> createState() => _Til1imAppState();
}

class _Til1imAppState extends State<Til1imApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.authCubit);
  }

  @override
  void dispose() {
    unawaited(widget.authCubit.close());
    unawaited(widget.settingsCubit.close());
    unawaited(widget.statisticsCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.authCubit),
        BlocProvider.value(value: widget.settingsCubit),
        BlocProvider.value(value: widget.statisticsCubit),
      ],
      child: BlocListener<SettingsCubit, SettingsState>(
        listenWhen: (prev, curr) {
          if (curr is! SettingsLoaded) return false;
          if (prev is SettingsLoaded) {
            return prev.settings.uiLanguage != curr.settings.uiLanguage;
          }
          return true;
        },
        listener: (ctx, state) {
          if (state is! SettingsLoaded) return;
          unawaited(ctx.setLocale(Locale(state.settings.uiLanguage.name)));
        },
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            return MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: app_theme.AppTheme.lightTheme,
              darkTheme: app_theme.AppTheme.darkTheme,
              themeMode: _resolveThemeMode(settingsState),
              routerConfig: _router,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
            );
          },
        ),
      ),
    );
  }

  ThemeMode _resolveThemeMode(SettingsState state) {
    if (state is! SettingsLoaded) return widget.initialThemeMode;
    return switch (state.settings.theme) {
      AppTheme.light => ThemeMode.light,
      AppTheme.dark => ThemeMode.dark,
      AppTheme.system => ThemeMode.system,
    };
  }
}
