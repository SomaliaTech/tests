import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/admin/data/datasources/admin_market_remote_data_source.dart';
import 'package:mobile/features/admin/domain/entities/market_entity.dart';
import 'package:mobile/features/admin/domain/repositories/admin_market_repository.dart';

class AdminMarketRepositoryImpl implements AdminMarketRepository {
  final AdminMarketRemoteDataSource remoteDataSource;

  AdminMarketRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MarketEntity>> getAllMarkets() async {
    try {
      return await remoteDataSource.getAllMarkets();
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> createMarket(Map<String, dynamic> data) async {
    try {
      await remoteDataSource.createMarket(data);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> updateMarket(String marketId, Map<String, dynamic> data) async {
    try {
      await remoteDataSource.updateMarket(marketId, data);
    } on ServerException {
      rethrow;
    }
  }

  // In admin_market_repository_impl.dart

  @override
  Future<void> deleteMarket(String marketId) async {
    try {
      final result = await remoteDataSource.deleteMarket(marketId);
      // If the result contains a deactivated message, it's not an error
      // The remote data source should handle this
      return result;
    } catch (e) {
      // Only throw if it's a real error
      if (e.toString().contains('BadRequestException') ||
          e.toString().contains('Cannot delete')) {
        throw ServerException(
          'Cannot delete this market because it has associated users. '
          'The market has been deactivated instead.',
        );
      }
      rethrow;
    }
  }
}
