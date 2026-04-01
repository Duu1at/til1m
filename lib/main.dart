import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wordup/core/constants/app_constants.dart';
import 'package:wordup/core/constants/supabase_constants.dart';
import 'package:wordup/core/di/service_locator.dart';
import 'package:wordup/core/router/app_router.dart';
import 'package:wordup/core/theme/app_theme.dart';
import 'package:wordup/domain/repositories/auth_repository.dart';
import 'package:wordup/presentation/blocs/auth/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Hive.initFlutter();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  setupServiceLocator();

  runApp(
    EasyLocalization(
      supportedLocales: AppConstants.supportedLocales,
      path: AppConstants.translationsPath,
      fallbackLocale: AppConstants.fallbackLocale,
      child: const WordUpApp(),
    ),
  );
}

class WordUpApp extends StatefulWidget {
  const WordUpApp({super.key});

  @override
  State<WordUpApp> createState() => _WordUpAppState();
}

class _WordUpAppState extends State<WordUpApp> {
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
        title: 'WordUp',
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
