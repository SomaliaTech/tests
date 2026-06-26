import 'package:mobile/features/admin/domain/entities/market_entity.dart';

abstract class AdminMarketRepository {
  Future<List<MarketEntity>> getAllMarkets();
  Future<void> createMarket(Map<String, dynamic> data);
  Future<void> updateMarket(String marketId, Map<String, dynamic> data);
  Future<void> deleteMarket(String marketId);
}
