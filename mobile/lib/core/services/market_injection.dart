import 'package:get_it/get_it.dart';
import 'package:mobile/features/profile/data/datasources/market_remote_datasource.dart';
import 'package:mobile/features/profile/data/repositories/market_repository_impl.dart';
import 'package:mobile/features/profile/domain/usecases/get_markets.dart';

void registerMarketDependencies(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<MarketRemoteDataSource>(
    () => MarketRemoteDataSourceImpl(client: sl()),
  );

  // Repositories
  sl.registerLazySingleton<MarketRepositoryImpl>(
    () => MarketRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetMarkets(sl()));
}
