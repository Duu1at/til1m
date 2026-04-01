import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wordup/core/constants/app_constants.dart';
import 'package:wordup/core/constants/supabase_constants.dart';
import 'package:wordup/core/router/app_router.dart';
import 'package:wordup/core/theme/app_theme.dart';
import 'package:wordup/data/repositories/auth_repository_impl.dart';
import 'package:wordup/presentation/blocs/auth/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Hive.initFlutter();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  final authRepository = AuthRepositoryImpl();
  final authCubit = AuthCubit(authRepository);
  final router = createRouter(authCubit);

  runApp(
    EasyLocalization(
      supportedLocales: AppConstants.supportedLocales,
      path: AppConstants.translationsPath,
      fallbackLocale: AppConstants.fallbackLocale,
      child: WordUpApp(authCubit: authCubit, router: router),
    ),
  );
}

class WordUpApp extends StatelessWidget {
  const WordUpApp({
    required this.authCubit,
    required this.router,
    super.key,
  });

  final AuthCubit authCubit;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authCubit,
      child: MaterialApp.router(
        title: 'WordUp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: router,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      ),
    );
  }
}
