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

  String get displayName => name;

  @override
  List<Object?> get props => [id, name, slug, city, isActive];
}
