import '../../domain/entities/analytics_entities.dart';

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
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      imageUrl: json['imageUrl'],
      totalSold: json['totalSold'] ?? 0,
      totalRevenue: _parseDouble(json['totalRevenue']),
      orderCount: json['orderCount'] ?? 0,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
      id: json['id'],
      name: json['name'] ?? 'Uncategorized',
      totalRevenue: _parseDouble(json['totalRevenue']),
      orderCount: json['orderCount'] ?? 0,
      itemCount: json['itemCount'] ?? 0,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
      status: json['status'] ?? 'UNKNOWN',
      count: json['count'] ?? 0,
      totalRevenue: _parseDouble(json['totalRevenue']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      stock: json['stock'] ?? 0,
      price: _parseDouble(json['price']),
      imageUrl: json['imageUrl'],
      categoryName: json['categoryName'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
      id: json['id'] ?? '',
      name: json['name'] ?? 'Anonymous',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
      isVerified: json['isVerified'] ?? false,
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
  });

  factory AnalyticsDataModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsDataModel(
      topProducts:
          (json['topProducts'] as List<dynamic>?)
              ?.map((p) => TopProductModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      revenueByCategory:
          (json['revenueByCategory'] as List<dynamic>?)
              ?.map(
                (c) => CategoryRevenueModel.fromJson(c as Map<String, dynamic>),
              )
              .toList() ??
          [],
      orderStatusDistribution:
          (json['orderStatusDistribution'] as List<dynamic>?)
              ?.map((s) => OrderStatusModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      lowStockProducts:
          (json['lowStockProducts'] as List<dynamic>?)
              ?.map(
                (p) => LowStockProductModel.fromJson(p as Map<String, dynamic>),
              )
              .toList() ??
          [],
      recentSignups:
          (json['recentSignups'] as List<dynamic>?)
              ?.map(
                (u) => RecentSignupModel.fromJson(u as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
