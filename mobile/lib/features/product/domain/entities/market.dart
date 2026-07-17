import 'package:equatable/equatable.dart';

class Market extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? city;
  final bool isActive;
  final int userCount; // ✅ Added
  final double deliveryPrice; // ✅ Added
  final int? freeDeliveryMinQuantity; // ✅ Added
  final int deliveryEstimationMinutes; // ✅ Added
  final DateTime createdAt;
  final DateTime updatedAt;

  const Market({
    required this.id,
    required this.name,
    required this.slug,
    this.city,
    required this.isActive,
    required this.userCount, // ✅ Added
    required this.deliveryPrice, // ✅ Added
    this.freeDeliveryMinQuantity, // ✅ Added
    required this.deliveryEstimationMinutes, // ✅ Added
    required this.createdAt,
    required this.updatedAt,
  });

  factory Market.fromJson(Map<String, dynamic> json) {
    return Market(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      city: json['city'],
      isActive: json['is_active'] ?? true,
      userCount: json['user_count'] ?? 0, // ✅ Added
      deliveryPrice:
          double.tryParse(json['delivery_price']?.toString() ?? '0.0') ??
          0.0, // ✅ Added
      freeDeliveryMinQuantity: json['free_delivery_min_quantity'], // ✅ Added
      deliveryEstimationMinutes:
          json['delivery_estimation_minutes'] ?? 90, // ✅ Added
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'city': city,
      'is_active': isActive,
      'user_count': userCount, // ✅ Added
      'delivery_price': deliveryPrice, // ✅ Added
      'free_delivery_min_quantity': freeDeliveryMinQuantity, // ✅ Added
      'delivery_estimation_minutes': deliveryEstimationMinutes, // ✅ Added
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Market copyWith({
    String? id,
    String? name,
    String? slug,
    String? city,
    bool? isActive,
    int? userCount, // ✅ Added
    double? deliveryPrice, // ✅ Added
    int? freeDeliveryMinQuantity, // ✅ Added
    int? deliveryEstimationMinutes, // ✅ Added
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Market(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      city: city ?? this.city,
      isActive: isActive ?? this.isActive,
      userCount: userCount ?? this.userCount, // ✅ Added
      deliveryPrice: deliveryPrice ?? this.deliveryPrice, // ✅ Added
      freeDeliveryMinQuantity:
          freeDeliveryMinQuantity ?? this.freeDeliveryMinQuantity, // ✅ Added
      deliveryEstimationMinutes:
          deliveryEstimationMinutes ??
          this.deliveryEstimationMinutes, // ✅ Added
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    city,
    isActive,
    userCount, // ✅ Added
    deliveryPrice, // ✅ Added
    freeDeliveryMinQuantity, // ✅ Added
    deliveryEstimationMinutes, // ✅ Added
    createdAt,
    updatedAt,
  ];
}
