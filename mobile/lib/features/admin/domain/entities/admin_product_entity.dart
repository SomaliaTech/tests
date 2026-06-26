import 'package:equatable/equatable.dart';

class AdminProductEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final int stock;
  final String? categoryId;
  final String? categoryName;
  final String? brand;
  final String? tags;
  final bool isActive;
  final List<AdminProductImageEntity> images;
  final List<AdminProductVariantEntity> variants;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminProductEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    required this.stock,
    this.categoryId,
    this.categoryName,
    this.brand,
    this.tags,
    required this.isActive,
    required this.images,
    required this.variants,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    description,
    price,
    stock,
    categoryId,
    categoryName,
    brand,
    tags,
    isActive,
    images,
    variants,
    createdAt,
    updatedAt,
  ];
}

class AdminProductImageEntity extends Equatable {
  final String id;
  final String url;
  final String publicId;
  final bool isMain;
  final int order;

  const AdminProductImageEntity({
    required this.id,
    required this.url,
    required this.publicId,
    required this.isMain,
    required this.order,
  });

  @override
  List<Object?> get props => [id, url, publicId, isMain, order];
}

// ✅ UPDATED: Added colorCode and sizeValue fields
class AdminProductVariantEntity extends Equatable {
  final String id;
  final String? sku;
  final int stock;
  final double? price;
  final String? colorId;
  final String? colorName;
  final String? colorCode; // ✅ NEW
  final String? sizeId;
  final String? sizeName;
  final String? sizeValue; // ✅ NEW

  const AdminProductVariantEntity({
    required this.id,
    this.sku,
    required this.stock,
    this.price,
    this.colorId,
    this.colorName,
    this.colorCode, // ✅ NEW
    this.sizeId,
    this.sizeName,
    this.sizeValue, // ✅ NEW
  });

  @override
  List<Object?> get props => [
    id,
    sku,
    stock,
    price,
    colorId,
    colorName,
    colorCode,
    sizeId,
    sizeName,
    sizeValue,
  ];
}

class AdminCategoryEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? parentId;
  final String? iconUrl; // ✅ NEW
  final List<AdminCategoryEntity> children;

  const AdminCategoryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.parentId,
    this.iconUrl, // ✅ NEW
    this.children = const [],
  });

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    description,
    parentId,
    iconUrl,
    children,
  ];
}
