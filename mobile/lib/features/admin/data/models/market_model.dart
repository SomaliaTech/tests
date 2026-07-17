import 'package:mobile/features/admin/domain/entities/market_entity.dart';

class MarketModel extends MarketEntity {
  const MarketModel({
    required super.id,
    required super.name,
    required super.slug,
    super.city,
    required super.isActive,
    required super.userCount, // ✅ Added userCount
    required super.deliveryPrice,
    super.freeDeliveryMinQuantity,
    required super.deliveryEstimationMinutes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MarketModel.fromJson(Map<String, dynamic> json) {
    return MarketModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      city: json['city'] as String?, // ✅ Allow null
      isActive: json['isActive'] ?? true,
      userCount: json['userCount'] ?? 0,
      deliveryPrice:
          double.tryParse(json['deliveryPrice']?.toString() ?? '0.0') ?? 0.0,
      freeDeliveryMinQuantity: json['freeDeliveryMinQuantity'],
      deliveryEstimationMinutes: json['deliveryEstimationMinutes'] ?? 90,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'city': city,
      'is_active': isActive,
      'user_count': userCount, // ✅ Added to JSON output
      'delivery_price': deliveryPrice,
      'free_delivery_min_quantity': freeDeliveryMinQuantity,
      'delivery_estimation_minutes': deliveryEstimationMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MarketModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? city,
    bool? isActive,
    int? userCount, // ✅ Added to copyWith
    double? deliveryPrice,
    int? freeDeliveryMinQuantity,
    int? deliveryEstimationMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      city: city ?? this.city,
      isActive: isActive ?? this.isActive,
      userCount: userCount ?? this.userCount, // ✅ Added to copyWith
      deliveryPrice: deliveryPrice ?? this.deliveryPrice,
      freeDeliveryMinQuantity:
          freeDeliveryMinQuantity ?? this.freeDeliveryMinQuantity,
      deliveryEstimationMinutes:
          deliveryEstimationMinutes ?? this.deliveryEstimationMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
