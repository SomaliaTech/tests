import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String description;
  final double price;
  final int stock;
  final bool isActive;
  final String categoryId;
  final String? categoryName;
  final String? brand;
  final List<String> imageUrls;
  final List<ProductVariant> variants;
  final DateTime createdAt;

  // Additional properties for product detail
  final List<String>? colors;
  final List<String>? sizes;
  final List<String>? features;
  final double? rating;
  final int? reviewCount;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.stock,
    required this.isActive,
    required this.categoryId,
    this.categoryName,
    this.brand,
    required this.imageUrls,
    required this.variants,
    required this.createdAt,
    this.colors,
    this.sizes,
    this.features,
    this.rating,
    this.reviewCount,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    stock,
    isActive,
    categoryId,
    imageUrls,
    variants,
    createdAt,
    colors,
    sizes,
    features,
    rating,
    reviewCount,
  ];

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  double get discountedPrice {
    // You can add discount logic here
    return price;
  }
}

class ProductVariant extends Equatable {
  final String id;
  final String? colorName;
  final String? sizeName;
  final double price;
  final int stock;

  const ProductVariant({
    required this.id,
    this.colorName,
    this.sizeName,
    required this.price,
    required this.stock,
  });

  @override
  List<Object?> get props => [id, colorName, sizeName, price, stock];
}
