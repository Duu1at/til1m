import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/data/datasources/local/progress_local_datasource.dart';
import 'package:til1m/data/datasources/remote/progress_remote_datasource.dart';
import 'package:til1m/data/repositories/auth_repository_impl.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  // Repositories
  sl
    ..registerLazySingleton<AuthRepository>(AuthRepositoryImpl.new)
    // DataSources
    ..registerLazySingleton<ProgressLocalDataSource>(
      ProgressLocalDataSource.new,
    )
    ..registerLazySingleton<ProgressRemoteDataSource>(
      () => ProgressRemoteDataSource(Supabase.instance.client),
    );
}
