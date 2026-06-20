// lib/features/product/domain/usecases/get_markets.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/market.dart';
import '../../domain/repositories/market_repository.dart';

// Use the correct repository import
// Delete the duplicate file in features/profile/domain/repositories/market_repository.dart
// and use this one instead

class GetMarkets {
  final MarketRepository repository;

  GetMarkets(this.repository);

  Future<Either<Failure, List<Market>>> call() async {
    return await repository.getMarkets();
  }
}
