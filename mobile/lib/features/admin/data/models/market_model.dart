import '../../domain/entities/market_entity.dart';

class MarketModel extends MarketEntity {
  const MarketModel({
    required super.id,
    required super.name,
    required super.slug,
    super.city,
    required super.isActive,
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
