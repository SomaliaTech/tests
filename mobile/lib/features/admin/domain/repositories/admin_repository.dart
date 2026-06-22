import 'package:mobile/features/admin/domain/entities/admin_stats_entity.dart';
import 'package:mobile/features/admin/domain/entities/admin_order_entity.dart';

abstract class AdminRepository {
  Future<AdminStatsEntity> getAdminStats();
  Future<List<AdminOrderEntity>> getAllOrders(String? search);
  Future<void> updateOrderStatus(String orderId, String newStatus);
}
