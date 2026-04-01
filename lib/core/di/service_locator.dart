import 'package:get_it/get_it.dart';
import 'package:wordup/data/repositories/auth_repository_impl.dart';
import 'package:wordup/domain/repositories/auth_repository.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  // Repositories
  sl.registerLazySingleton<AuthRepository>(AuthRepositoryImpl.new);
}
