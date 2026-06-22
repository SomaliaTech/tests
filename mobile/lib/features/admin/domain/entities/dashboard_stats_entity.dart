import 'package:equatable/equatable.dart';

class DashboardStatsEntity extends Equatable {
  final int totalUsers;
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;
  final int newUsers;
  final int ordersInPeriod;
  final double userGrowth;
  final String period;

  const DashboardStatsEntity({
    required this.totalUsers,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalRevenue,
    required this.newUsers,
    required this.ordersInPeriod,
    required this.userGrowth,
    required this.period,
  });

  @override
  List<Object?> get props => [
    totalUsers,
    totalProducts,
    totalOrders,
    totalRevenue,
    newUsers,
    ordersInPeriod,
    userGrowth,
    period,
  ];
}
