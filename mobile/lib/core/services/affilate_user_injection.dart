import 'package:get_it/get_it.dart';
import 'package:mobile/features/affiliate/data/datasources/affiliate_user_remote_data_source.dart';
import 'package:mobile/features/affiliate/data/repositories/affiliate_user_repository_impl.dart';
import 'package:mobile/features/affiliate/domain/repositories/affiliate_user_repository.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_bloc.dart';

void registerAffiliateUserDependencies(GetIt sl) {
  sl.registerLazySingleton<AffiliateUserRemoteDataSource>(
    () => AffiliateUserRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );

  sl.registerLazySingleton<AffiliateUserRepository>(
    () => AffiliateUserRepositoryImpl(remote: sl()),
  );

  sl.registerFactory(() => AffiliateUserBloc(repository: sl(), storage: sl()));
}
