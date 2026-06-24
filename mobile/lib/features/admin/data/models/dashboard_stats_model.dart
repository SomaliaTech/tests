import 'package:mobile/features/admin/domain/entities/dashboard_stats_entity.dart';

class DashboardStatsModel extends DashboardStatsEntity {
  const DashboardStatsModel({
    required super.totalUsers,
    required super.totalOrders,
    required super.totalRevenue,
    required super.newUsers,
    required super.userGrowth,
    required super.orderGrowth,
    required super.revenueGrowth,
    required super.newUserGrowth,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalUsers: json['totalUsers'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      newUsers: json['newUsers'] ?? 0,
      userGrowth: (json['userGrowth'] ?? 0).toDouble(),
      orderGrowth: (json['orderGrowth'] ?? 0).toDouble(),
      revenueGrowth: (json['revenueGrowth'] ?? 0).toDouble(),
      newUserGrowth: (json['newUserGrowth'] ?? 0).toDouble(),
    );
  }
}
