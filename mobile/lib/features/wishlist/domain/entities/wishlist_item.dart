import 'package:equatable/equatable.dart';

class WishlistItem extends Equatable {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String? brand;
  final double? rating;
  final String categoryId;
  final String productVariantId; // Add this

  const WishlistItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.brand,
    this.rating,
    required this.categoryId,
    required this.productVariantId, // Add this
  });

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get ratingString => rating?.toStringAsFixed(1) ?? '0.0';

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    imageUrl,
    brand,
    rating,
    categoryId,
    productVariantId,
  ];
}
