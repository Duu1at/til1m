import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wordup/core/constants/app_constants.dart';
import 'package:wordup/core/constants/supabase_constants.dart';
import 'package:wordup/core/router/app_router.dart';
import 'package:wordup/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Hive.initFlutter();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  runApp(
    EasyLocalization(
      supportedLocales: AppConstants.supportedLocales,
      path: AppConstants.translationsPath,
      fallbackLocale: AppConstants.fallbackLocale,
      child: const WordUpApp(),
    ),
  );
}

class WordUpApp extends StatelessWidget {
  const WordUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WordUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
