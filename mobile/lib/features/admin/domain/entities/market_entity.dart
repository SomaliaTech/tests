// lib/features/admin/domain/entities/market_entity.dart
class MarketEntity {
  final String id;
  final String name;
  final String slug;
  final String? city;
  final bool isActive;
  final int? userCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.city,
    required this.isActive,
    this.userCount,
    required this.createdAt,
    required this.updatedAt,
  });
}
