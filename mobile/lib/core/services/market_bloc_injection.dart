// lib/core/services/market_injection.dart
import 'package:get_it/get_it.dart';
import 'package:mobile/features/profile/data/datasources/market_remote_datasource.dart';
import 'package:mobile/features/profile/data/repositories/market_repository_impl.dart';
import 'package:mobile/features/profile/domain/repositories/market_repository.dart';
import 'package:mobile/features/product/domain/usecases/get_markets.dart';
import 'package:mobile/features/product/presentation/blocs/market_bloc/market_bloc.dart';

void registerMarketDependencies(GetIt sl) {
  print('🔄 Registering Market Dependencies...');

  // Data Sources
  if (!sl.isRegistered<MarketRemoteDataSource>()) {
    print('📦 Registering MarketRemoteDataSource...');
    sl.registerLazySingleton<MarketRemoteDataSource>(
      () => MarketRemoteDataSourceImpl(client: sl()),
    );
  }

  // Repositories
  if (!sl.isRegistered<MarketRepository>()) {
    print('📦 Registering MarketRepository...');
    sl.registerLazySingleton<MarketRepository>(
      () => MarketRepositoryImpl(remoteDataSource: sl()),
    );
  }

  // Use Cases
  if (!sl.isRegistered<GetMarkets>()) {
    print('📦 Registering GetMarkets...');
    sl.registerLazySingleton(() => GetMarkets(sl()));
  }

  // BLoCs - Use registerFactory for BLoCs
  if (!sl.isRegistered<MarketBloc>()) {
    print('📦 Registering MarketBloc...');
    sl.registerFactory(() => MarketBloc(getMarkets: sl()));
  }

  print('✅ Market Dependencies Registered Successfully');
}
