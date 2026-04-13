import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/network/connectivity_service.dart';
import 'package:til1m/data/datasources/local/flashcard_local_datasource.dart';
import 'package:til1m/data/datasources/local/progress_local_datasource.dart';
import 'package:til1m/data/datasources/local/word_local_datasource.dart';
import 'package:til1m/data/datasources/remote/flashcard_remote_datasource.dart';
import 'package:til1m/data/datasources/remote/progress_remote_datasource.dart';
import 'package:til1m/data/datasources/remote/word_remote_datasource.dart';
import 'package:til1m/data/datasources/sync/progress_sync_service.dart';
import 'package:til1m/data/repositories/auth_repository_impl.dart';
import 'package:til1m/data/repositories/flashcard_repository_impl.dart';
import 'package:til1m/data/repositories/word_repository_impl.dart';
import 'package:til1m/data/services/migrate_guest_progress.dart';
import 'package:til1m/data/services/update_home_widget.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/domain/repositories/word_repository.dart';
import 'package:til1m/domain/usecases/prefetch_flashcard_data.dart';
import 'package:til1m/services/widget_service/widget_service.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  sl
    // HTTP client — shared, configured with timeouts
    ..registerLazySingleton<Dio>(
      () => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ),
    )
    // Repositories
    ..registerLazySingleton<AuthRepository>(AuthRepositoryImpl.new)
    // Network
    ..registerLazySingleton<ConnectivityService>(ConnectivityService.new)
    // DataSources — local
    ..registerLazySingleton<ProgressLocalDataSource>(
      ProgressLocalDataSource.new,
    )
    ..registerLazySingleton<WordLocalDataSource>(WordLocalDataSource.new)
    ..registerLazySingleton<FlashcardLocalDataSource>(
      FlashcardLocalDataSource.new,
    )
    // DataSources — remote
    ..registerLazySingleton<ProgressRemoteDataSource>(
      () => ProgressRemoteDataSource(Supabase.instance.client),
    )
    ..registerLazySingleton<WordRemoteDataSource>(
      () => WordRemoteDataSource(Supabase.instance.client),
    )
    ..registerLazySingleton<FlashcardRemoteDataSource>(
      () => FlashcardRemoteDataSource(Supabase.instance.client),
    )
    // Sync service
    ..registerLazySingleton<ProgressSyncService>(
      () => ProgressSyncService(Supabase.instance.client),
    )
    // Word repository
    ..registerLazySingleton<WordRepository>(
      () => WordRepositoryImpl(
        remote: sl<WordRemoteDataSource>(),
        local: sl<WordLocalDataSource>(),
      ),
    )
    // Flashcard repository (concrete — has extra session/queue methods)
    ..registerLazySingleton<FlashcardRepositoryImpl>(
      () => FlashcardRepositoryImpl(
        remote: sl<FlashcardRemoteDataSource>(),
        local: sl<FlashcardLocalDataSource>(),
        authRepo: sl<AuthRepository>(),
        connectivity: sl<ConnectivityService>(),
        syncService: sl<ProgressSyncService>(),
      ),
    )
    // Prefetch use case
    ..registerLazySingleton<PrefetchFlashcardData>(
      () => PrefetchFlashcardData(
        flashcardRepo: sl<FlashcardRepositoryImpl>(),
        authRepo: sl<AuthRepository>(),
      ),
    )
    // Guest progress migration
    ..registerLazySingleton<MigrateGuestProgress>(
      () => MigrateGuestProgress(Supabase.instance.client),
    )
    // Home widget updater
    ..registerLazySingleton<UpdateHomeWidget>(
      () => UpdateHomeWidget(
        flashcardRepo: sl<FlashcardRepositoryImpl>(),
        authRepo: sl<AuthRepository>(),
      ),
    )
    // Widget service — uses shared Dio for image caching
    ..registerLazySingleton<WidgetService>(() => WidgetService(dio: sl<Dio>()));
}
