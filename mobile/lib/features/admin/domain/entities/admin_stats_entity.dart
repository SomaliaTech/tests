import 'package:equatable/equatable.dart';

class AdminStatsEntity extends Equatable {
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;
  final int totalUsers;

  const AdminStatsEntity({
    required this.totalProducts,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalUsers,
  });

  @override
  List<Object?> get props => [
    totalProducts,
    totalOrders,
    totalRevenue,
    totalUsers,
  ];
}
