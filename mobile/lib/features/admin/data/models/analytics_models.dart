import 'package:mobile/features/admin/domain/entities/analytics_entities.dart';

class DailyRevenueModel extends DailyRevenueEntity {
  const DailyRevenueModel({
    required super.date,
    required super.revenue,
    required super.orders,
  });

  factory DailyRevenueModel.fromJson(Map<String, dynamic> json) {
    return DailyRevenueModel(
      date: json['date'] as String,
      revenue: (json['revenue'] is num)
          ? (json['revenue'] as num).toDouble()
          : double.parse(json['revenue'].toString()),
      orders: json['orders'] as int? ?? 0,
    );
  }
}

class TopProductModel extends TopProductEntity {
  const TopProductModel({
    required super.id,
    required super.name,
    super.imageUrl,
    required super.totalSold,
    required super.totalRevenue,
    required super.orderCount,
  });

  factory TopProductModel.fromJson(Map<String, dynamic> json) {
    return TopProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      totalSold: json['totalSold'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] is num)
          ? (json['totalRevenue'] as num).toDouble()
          : double.parse(json['totalRevenue'].toString()),
      orderCount: json['orderCount'] as int? ?? 0,
    );
  }
}

class CategoryRevenueModel extends CategoryRevenueEntity {
  const CategoryRevenueModel({
    super.id,
    required super.name,
    required super.totalRevenue,
    required super.orderCount,
    required super.itemCount,
  });

  factory CategoryRevenueModel.fromJson(Map<String, dynamic> json) {
    return CategoryRevenueModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      totalRevenue: (json['totalRevenue'] is num)
          ? (json['totalRevenue'] as num).toDouble()
          : double.parse(json['totalRevenue'].toString()),
      orderCount: json['orderCount'] as int? ?? 0,
      itemCount: json['itemCount'] as int? ?? 0,
    );
  }
}

class OrderStatusModel extends OrderStatusEntity {
  const OrderStatusModel({
    required super.status,
    required super.count,
    required super.totalRevenue,
  });

  factory OrderStatusModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusModel(
      status: json['status'] as String,
      count: json['count'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] is num)
          ? (json['totalRevenue'] as num).toDouble()
          : double.parse(json['totalRevenue'].toString()),
    );
  }
}

class LowStockProductModel extends LowStockProductEntity {
  const LowStockProductModel({
    required super.id,
    required super.name,
    required super.stock,
    required super.price,
    super.imageUrl,
    super.categoryName,
  });

  factory LowStockProductModel.fromJson(Map<String, dynamic> json) {
    return LowStockProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      stock: json['stock'] as int? ?? 0,
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.parse(json['price'].toString()),
      imageUrl: json['imageUrl'] as String?,
      categoryName: json['categoryName'] as String?,
    );
  }
}

class RecentSignupModel extends RecentSignupEntity {
  const RecentSignupModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
    super.email,
    required super.joinedAt,
    required super.isVerified,
  });

  factory RecentSignupModel.fromJson(Map<String, dynamic> json) {
    return RecentSignupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

class AnalyticsDataModel extends AnalyticsDataEntity {
  const AnalyticsDataModel({
    required super.topProducts,
    required super.revenueByCategory,
    required super.orderStatusDistribution,
    required super.lowStockProducts,
    required super.recentSignups,
    super.dailyRevenue,
    super.selectedDates,
  });

  factory AnalyticsDataModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsDataModel(
      topProducts: (json['topProducts'] as List? ?? [])
          .map((e) => TopProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      revenueByCategory: (json['revenueByCategory'] as List? ?? [])
          .map((e) => CategoryRevenueModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      orderStatusDistribution: (json['orderStatusDistribution'] as List? ?? [])
          .map((e) => OrderStatusModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      lowStockProducts: (json['lowStockProducts'] as List? ?? [])
          .map((e) => LowStockProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentSignups: (json['recentSignups'] as List? ?? [])
          .map((e) => RecentSignupModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyRevenue: json['dailyRevenue'] != null
          ? (json['dailyRevenue'] as List)
                .map(
                  (e) => DailyRevenueModel.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
      selectedDates: json['selectedDates'] != null
          ? (json['selectedDates'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }
}
