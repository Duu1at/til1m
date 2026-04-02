import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/supabase_constants.dart';
import 'package:til1m/core/di/service_locator.dart';
import 'package:til1m/core/router/app_router.dart';
import 'package:til1m/core/theme/app_theme.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/presentation/blocs/auth/auth_cubit.dart';

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

  runApp(
    EasyLocalization(
      supportedLocales: AppConstants.supportedLocales,
      path: AppConstants.translationsPath,
      fallbackLocale: AppConstants.fallbackLocale,
      child: const Til1imApp(),
    ),
  );
}

class Til1imApp extends StatefulWidget {
  const Til1imApp({super.key});

  @override
  State<Til1imApp> createState() => _Til1imAppState();
}

class _Til1imAppState extends State<Til1imApp> {
  late final AuthCubit _authCubit;
  late final GoRouter _router = createRouter(_authCubit);

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(sl<AuthRepository>());
  }

  @override
  void dispose() {
    unawaited(_authCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: MaterialApp.router(
        title: 'Til1m',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: _router,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      ),
    );
  }
}
