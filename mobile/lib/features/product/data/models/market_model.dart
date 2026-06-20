// lib/features/profile/domain/entities/market.dart
import 'package:equatable/equatable.dart';

class Market extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? city;
  final bool isActive;

  const Market({
    required this.id,
    required this.name,
    required this.slug,
    this.city,
    this.isActive = true,
  });

  factory Market.fromJson(Map<String, dynamic> json) {
    return Market(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      city: json['city'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'city': city,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [id, name, slug, city, isActive];
}
