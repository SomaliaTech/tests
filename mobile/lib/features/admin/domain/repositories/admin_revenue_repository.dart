import 'package:mobile/features/admin/domain/entities/admin_revenue_entity.dart';

abstract class AdminRevenueRepository {
  Future<AdminRevenueSummaryEntity> getRevenueSummary(String period);
  Future<({List<AdminRevenueListEntity> data, int total})> getAllRevenue({
    String? search,
    String? paymentMethod,
    String? status,
    int limit,
    int offset,
  });
  Future<AdminRevenueEntity> getRevenueById(String orderId);
}
