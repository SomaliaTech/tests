import '../../../../core/utils/typedefs.dart';
import '../entities/market.dart';

abstract class MarketRepository {
  ResultFuture<List<Market>> getMarkets();
  ResultFuture<Market> getMarketById(String id);
  ResultFuture<Market> getMarketBySlug(String slug);
}
