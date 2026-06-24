import 'package:equatable/equatable.dart';

class DashboardStatsEntity extends Equatable {
  final int totalUsers;
  final int totalOrders;
  final double totalRevenue;
  final int newUsers;
  final double userGrowth;
  final double orderGrowth;
  final double revenueGrowth;
  final double newUserGrowth;

  const DashboardStatsEntity({
    required this.totalUsers,
    required this.totalOrders,
    required this.totalRevenue,
    required this.newUsers,
    required this.userGrowth,
    required this.orderGrowth,
    required this.revenueGrowth,
    required this.newUserGrowth,
  });

  @override
  List<Object?> get props => [
    totalUsers,
    totalOrders,
    totalRevenue,
    newUsers,
    userGrowth,
    orderGrowth,
    revenueGrowth,
    newUserGrowth,
  ];
}
