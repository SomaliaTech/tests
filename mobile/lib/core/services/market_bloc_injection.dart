// lib/core/services/market_injection.dart
import 'package:get_it/get_it.dart';
import 'package:mobile/features/profile/data/datasources/market_remote_datasource.dart';
import 'package:mobile/features/profile/data/repositories/market_repository_impl.dart';
import 'package:mobile/features/profile/domain/repositories/market_repository.dart';
import 'package:mobile/features/product/domain/usecases/get_markets.dart';
import 'package:mobile/features/product/presentation/blocs/market_bloc/market_bloc.dart';
import 'package:flutter/foundation.dart';

void registerMarketDependencies(GetIt sl) {
  if (kDebugMode) debugPrint('🔄 Registering Market Dependencies...');

  // Data Sources
  if (!sl.isRegistered<MarketRemoteDataSource>()) {
    if (kDebugMode) debugPrint('📦 Registering MarketRemoteDataSource...');
    sl.registerLazySingleton<MarketRemoteDataSource>(
      () => MarketRemoteDataSourceImpl(client: sl()),
    );
  }

  // Repositories
  if (!sl.isRegistered<MarketRepository>()) {
    if (kDebugMode) debugPrint('📦 Registering MarketRepository...');
    sl.registerLazySingleton<MarketRepository>(
      () => MarketRepositoryImpl(remoteDataSource: sl()),
    );
  }

  // Use Cases
  if (!sl.isRegistered<GetMarkets>()) {
    if (kDebugMode) debugPrint('📦 Registering GetMarkets...');
    sl.registerLazySingleton(() => GetMarkets(sl()));
  }

  // BLoCs - Use registerFactory for BLoCs
  if (!sl.isRegistered<MarketBloc>()) {
    if (kDebugMode) debugPrint('📦 Registering MarketBloc...');
    sl.registerFactory(() => MarketBloc(getMarkets: sl()));
  }

  if (kDebugMode) debugPrint('✅ Market Dependencies Registered Successfully');
}
