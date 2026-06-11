import 'package:get_it/get_it.dart';
import 'package:mobile/features/profile/data/datasources/market_remote_datasource.dart';
import 'package:mobile/features/profile/data/repositories/market_repository_impl.dart';
import 'package:mobile/features/profile/domain/repositories/market_repository.dart';
import 'package:mobile/features/profile/domain/usecases/get_markets.dart';

void registerMarketDependencies(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<MarketRemoteDataSource>(
    () => MarketRemoteDataSourceImpl(client: sl()),
  );

  // Repository
  sl.registerLazySingleton<MarketRepository>(
    () => MarketRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Case
  sl.registerLazySingleton(() => GetMarkets(sl()));
}
