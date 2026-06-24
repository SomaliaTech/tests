import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/admin/data/datasources/admin_revenue_remote_data_source.dart';
import 'package:mobile/features/admin/domain/entities/admin_revenue_entity.dart';
import 'package:mobile/features/admin/domain/repositories/admin_revenue_repository.dart';

class AdminRevenueRepositoryImpl implements AdminRevenueRepository {
  final AdminRevenueRemoteDataSource remoteDataSource;

  AdminRevenueRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AdminRevenueSummaryEntity> getRevenueSummary(String period) async {
    try {
      return await remoteDataSource.getRevenueSummary(period);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<({List<AdminRevenueListEntity> data, int total})> getAllRevenue({
    String? search,
    String? paymentMethod,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await remoteDataSource.getAllRevenue(
        search: search,
        paymentMethod: paymentMethod,
        status: status,
        limit: limit,
        offset: offset,
      );
      return (
        data: result.data.cast<AdminRevenueListEntity>(),
        total: result.total,
      );
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<AdminRevenueEntity> getRevenueById(String orderId) async {
    try {
      return await remoteDataSource.getRevenueById(orderId);
    } on ServerException {
      rethrow;
    }
  }
}
