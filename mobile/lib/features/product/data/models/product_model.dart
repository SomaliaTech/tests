import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.description,
    required super.price,
    required super.stock,
    required super.isActive,
    required super.categoryId,
    super.categoryName,
    super.brand,
    required super.imageUrls,
    required super.variants,
    required super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Safe price parsing
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    // Parse images
    List<String> parseImages(dynamic imagesData) {
      if (imagesData == null) return [];
      if (imagesData is List) {
        return imagesData
            .map((img) {
              if (img is String) return img;
              if (img is Map && img['url'] != null) return img['url'] as String;
              return '';
            })
            .where((url) => url.isNotEmpty)
            .toList();
      }
      return [];
    }

    // Parse variants
    List<ProductVariant> parseVariants(dynamic variantsData) {
      if (variantsData == null) return [];
      if (variantsData is List) {
        return variantsData
            .map(
              (v) => ProductVariant(
                id: v['id'] as String? ?? '',
                colorName: v['colorName'] as String?,
                sizeName: v['sizeName'] as String?,
                price: parsePrice(v['price']),
                stock: v['stock'] as int? ?? 0,
              ),
            )
            .toList();
      }
      return [];
    }

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: parsePrice(json['price']),
      stock: json['stock'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String?,
      brand: json['brand'] as String?,
      imageUrls: parseImages(json['images']),
      variants: parseVariants(json['variants']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
