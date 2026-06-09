import '../../../../core/utils/typedefs.dart';
import '../entities/market.dart';
import '../repositories/market_repository.dart';

class GetMarkets {
  final MarketRepository repository;

  const GetMarkets(this.repository);

  ResultFuture<List<Market>> call() async {
    return await repository.getMarkets();
  }
}
