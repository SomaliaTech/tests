import 'package:equatable/equatable.dart';

class MarketEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? city;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.city,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    city,
    isActive,
    createdAt,
    updatedAt,
  ];
}
