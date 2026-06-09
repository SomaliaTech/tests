import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/market.dart';
import '../../domain/repositories/market_repository.dart';
import '../datasources/market_remote_datasource.dart';

class MarketRepositoryImpl implements MarketRepository {
  final MarketRemoteDataSource remoteDataSource;

  const MarketRepositoryImpl({required this.remoteDataSource});

  @override
  ResultFuture<List<Market>> getMarkets() async {
    try {
      final markets = await remoteDataSource.getMarkets();
      return Right(markets);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<Market> getMarketById(String id) async {
    try {
      final markets = await remoteDataSource.getMarkets();
      final market = markets.firstWhere((m) => m.id == id);
      return Right(market);
    } catch (e) {
      return Left(ServerFailure('Market not found: $e'));
    }
  }

  @override
  ResultFuture<Market> getMarketBySlug(String slug) async {
    try {
      final markets = await remoteDataSource.getMarkets();
      final market = markets.firstWhere((m) => m.slug == slug);
      return Right(market);
    } catch (e) {
      return Left(ServerFailure('Market not found: $e'));
    }
  }
}
