import '../../domain/entities/admin_product_entity.dart';

class AdminProductModel extends AdminProductEntity {
  const AdminProductModel({
    required super.id,
    required super.name,
    required super.slug,
    super.description,
    required super.price,
    required super.stock,
    super.categoryId,
    super.categoryName,
    super.brand,
    super.tags,
    required super.isActive,
    required super.images,
    required super.variants,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdminProductModel.fromJson(Map<String, dynamic> json) {
    return AdminProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      price: _parseDouble(json['price']),
      stock: _parseInt(json['stock']),
      categoryId: json['categoryId'] ?? json['category']?['id'],
      categoryName: json['category']?['name'],
      brand: json['brand'],
      tags: json['tags'],
      isActive: json['isActive'] ?? true,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((img) => AdminProductImageModel.fromJson(img))
              .toList() ??
          [],
      variants:
          (json['variants'] as List<dynamic>?)
              ?.map((v) => AdminProductVariantModel.fromJson(v))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // ✅ Helper: Parse any numeric type to double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ✅ Helper: Parse any numeric type to int
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class AdminProductImageModel extends AdminProductImageEntity {
  const AdminProductImageModel({
    required super.id,
    required super.url,
    required super.publicId,
    required super.isMain,
    required super.order,
  });

  factory AdminProductImageModel.fromJson(Map<String, dynamic> json) {
    return AdminProductImageModel(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? '',
      isMain: json['isMain'] ?? false,
      order: json['order'] ?? 0,
    );
  }
}

class AdminProductVariantModel extends AdminProductVariantEntity {
  const AdminProductVariantModel({
    required super.id,
    super.sku,
    required super.stock,
    super.price,
    super.colorId,
    super.colorName,
    super.sizeId,
    super.sizeName,
  });

  factory AdminProductVariantModel.fromJson(Map<String, dynamic> json) {
    return AdminProductVariantModel(
      id: json['id'] ?? '',
      sku: json['sku'],
      stock: _parseInt(json['stock']),
      price: _parseDouble(json['price']),
      colorId: json['colorId'] ?? json['color']?['id'],
      colorName: json['color']?['name'],
      sizeId: json['sizeId'] ?? json['size']?['id'],
      sizeName: json['size']?['name'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class AdminCategoryModel extends AdminCategoryEntity {
  const AdminCategoryModel({
    required super.id,
    required super.name,
    required super.slug,
    super.description,
    super.parentId,
    super.children = const [],
  });

  factory AdminCategoryModel.fromJson(Map<String, dynamic> json) {
    return AdminCategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      parentId: json['parentId'],
      children:
          (json['children'] as List<dynamic>?)
              ?.map((c) => AdminCategoryModel.fromJson(c))
              .toList() ??
          [],
    );
  }
}
