import '../../domain/entities/market.dart';

class MarketModel {
  const MarketModel._();

  static Market fromJson(Map<String, dynamic> json) {
    return Market(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      city: json['city'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> toJson(Market market) {
    return {
      'id': market.id,
      'name': market.name,
      'slug': market.slug,
      'city': market.city,
      'isActive': market.isActive,
    };
  }
}
