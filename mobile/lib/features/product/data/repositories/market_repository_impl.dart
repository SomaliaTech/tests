// lib/features/profile/data/repositories/market_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/failures.dart';

import '../../domain/entities/market.dart';
import '../../domain/repositories/market_repository.dart';
import '../datasources/market_remote_datasource.dart';

class MarketRepositoryImpl implements MarketRepository {
  final MarketRemoteDataSource remoteDataSource;

  MarketRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Market>>> getMarkets() async {
    try {
      final markets = await remoteDataSource.getMarkets();
      return Right(markets);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Market>> getMarketById(String id) async {
    try {
      final market = await remoteDataSource.getMarketById(id);
      return Right(market);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Market>> getMarketBySlug(String slug) async {
    try {
      final market = await remoteDataSource.getMarketBySlug(slug);
      return Right(market);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
