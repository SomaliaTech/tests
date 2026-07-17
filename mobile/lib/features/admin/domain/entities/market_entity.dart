import 'package:equatable/equatable.dart';

class MarketEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? city;
  final bool isActive;
  final int userCount; // ✅ Added userCount field

  // ✅ NEW: Add delivery fields
  final double deliveryPrice;
  final int? freeDeliveryMinQuantity;
  final int deliveryEstimationMinutes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.city,
    required this.isActive,
    required this.userCount, // ✅ Added userCount parameter
    required this.deliveryPrice,
    this.freeDeliveryMinQuantity,
    required this.deliveryEstimationMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketEntity.fromJson(Map<String, dynamic> json) {
    return MarketEntity(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      city: json['city'],
      isActive: json['is_active'] ?? true,
      userCount: json['user_count'] ?? 0, // ✅ Parse userCount from JSON
      // ✅ Parse the delivery fields from JSON
      deliveryPrice:
          double.tryParse(json['delivery_price']?.toString() ?? '0.0') ?? 0.0,
      freeDeliveryMinQuantity: json['free_delivery_min_quantity'],
      deliveryEstimationMinutes: json['delivery_estimation_minutes'] ?? 90,

      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    city,
    isActive,
    userCount, // ✅ Added to props
    deliveryPrice,
    freeDeliveryMinQuantity,
    deliveryEstimationMinutes,
    createdAt,
    updatedAt,
  ];
}
