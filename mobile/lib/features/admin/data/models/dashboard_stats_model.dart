import 'package:mobile/features/admin/domain/entities/dashboard_stats_entity.dart';

class DashboardStatsModel extends DashboardStatsEntity {
  const DashboardStatsModel({
    required super.totalUsers,
    required super.totalProducts,
    required super.totalOrders,
    required super.totalRevenue,
    required super.newUsers,
    required super.ordersInPeriod,
    required super.userGrowth,
    required super.period,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalUsers: json['totalUsers'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      newUsers: json['newUsers'] ?? 0,
      ordersInPeriod: json['ordersInPeriod'] ?? 0,
      userGrowth: (json['userGrowth'] ?? 0).toDouble(),
      period: json['period'] ?? 'week',
    );
  }
}
