// lib/features/profile/domain/repositories/market_repository.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/market.dart';

abstract class MarketRepository {
  Future<Either<Failure, List<Market>>> getMarkets();

  // Add these missing methods
  Future<Either<Failure, Market>> getMarketById(String id);
  Future<Either<Failure, Market>> getMarketBySlug(String slug);
}
