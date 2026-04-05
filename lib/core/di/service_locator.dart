import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/data/datasources/local/progress_local_datasource.dart';
import 'package:til1m/data/datasources/local/word_local_datasource.dart';
import 'package:til1m/data/datasources/remote/progress_remote_datasource.dart';
import 'package:til1m/data/datasources/remote/word_remote_datasource.dart';
import 'package:til1m/data/repositories/auth_repository_impl.dart';
import 'package:til1m/data/repositories/word_repository_impl.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/domain/repositories/word_repository.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  sl
    // Repositories
    ..registerLazySingleton<AuthRepository>(AuthRepositoryImpl.new)
    // DataSources — local
    ..registerLazySingleton<ProgressLocalDataSource>(ProgressLocalDataSource.new)
    ..registerLazySingleton<WordLocalDataSource>(WordLocalDataSource.new)
    // DataSources — remote
    ..registerLazySingleton<ProgressRemoteDataSource>(
      () => ProgressRemoteDataSource(Supabase.instance.client),
    )
    ..registerLazySingleton<WordRemoteDataSource>(
      () => WordRemoteDataSource(Supabase.instance.client),
    )
    // Word repository
    ..registerLazySingleton<WordRepository>(
      () => WordRepositoryImpl(
        remote: sl<WordRemoteDataSource>(),
        local: sl<WordLocalDataSource>(),
      ),
    );
}
