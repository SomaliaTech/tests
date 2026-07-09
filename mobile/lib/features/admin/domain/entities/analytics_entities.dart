import 'package:equatable/equatable.dart';

class TopProductEntity extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final int totalSold;
  final double totalRevenue;
  final int orderCount;

  const TopProductEntity({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.totalSold,
    required this.totalRevenue,
    required this.orderCount,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    imageUrl,
    totalSold,
    totalRevenue,
    orderCount,
  ];
}

class CategoryRevenueEntity extends Equatable {
  final String? id;
  final String name;
  final double totalRevenue;
  final int orderCount;
  final int itemCount;

  const CategoryRevenueEntity({
    this.id,
    required this.name,
    required this.totalRevenue,
    required this.orderCount,
    required this.itemCount,
  });

  @override
  List<Object?> get props => [id, name, totalRevenue, orderCount, itemCount];
}

class OrderStatusEntity extends Equatable {
  final String status;
  final int count;
  final double totalRevenue;

  const OrderStatusEntity({
    required this.status,
    required this.count,
    required this.totalRevenue,
  });

  @override
  List<Object?> get props => [status, count, totalRevenue];
}

class LowStockProductEntity extends Equatable {
  final String id;
  final String name;
  final int stock;
  final double price;
  final String? imageUrl;
  final String? categoryName;

  const LowStockProductEntity({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    this.imageUrl,
    this.categoryName,
  });

  @override
  List<Object?> get props => [id, name, stock, price, imageUrl, categoryName];
}

class RecentSignupEntity extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final DateTime joinedAt;
  final bool isVerified;

  const RecentSignupEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.joinedAt,
    required this.isVerified,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    phoneNumber,
    email,
    joinedAt,
    isVerified,
  ];
}

class AnalyticsDataEntity extends Equatable {
  final List<TopProductEntity> topProducts;
  final List<CategoryRevenueEntity> revenueByCategory;
  final List<OrderStatusEntity> orderStatusDistribution;
  final List<LowStockProductEntity> lowStockProducts;
  final List<RecentSignupEntity> recentSignups;

  const AnalyticsDataEntity({
    required this.topProducts,
    required this.revenueByCategory,
    required this.orderStatusDistribution,
    required this.lowStockProducts,
    required this.recentSignups,
  });

  @override
  List<Object?> get props => [
    topProducts,
    revenueByCategory,
    orderStatusDistribution,
    lowStockProducts,
    recentSignups,
  ];
}
