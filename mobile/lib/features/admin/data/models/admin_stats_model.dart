import 'package:mobile/features/admin/domain/entities/admin_stats_entity.dart';

class AdminStatsModel extends AdminStatsEntity {
  const AdminStatsModel({
    required super.totalProducts,
    required super.totalOrders,
    required super.totalRevenue,
    required super.totalUsers,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      totalProducts: json['totalProducts'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalUsers: json['totalUsers'] ?? 0,
    );
  }
}
