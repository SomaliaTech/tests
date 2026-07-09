// lib/features/admin/data/models/market_model.dart
import '../../domain/entities/market_entity.dart';

class MarketModel extends MarketEntity {
  const MarketModel({
    required super.id,
    required super.name,
    required super.slug,
    super.city,
    required super.isActive,
    super.userCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MarketModel.fromJson(Map<String, dynamic> json) {
    return MarketModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      city: json['city'],
      isActive: json['isActive'] ?? true,
      userCount: json['userCount'] != null
          ? int.tryParse(json['userCount'].toString())
          : null,
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
      'isActive': isActive,
      'userCount': userCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
