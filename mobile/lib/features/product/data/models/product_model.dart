import '../../domain/entities/product.dart';

class ProductModel {
  const ProductModel._();

  static Product fromJson(Map<String, dynamic> json) {
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

    return Product(
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
      colors:
          (json['colors'] as List?)?.map((c) => c.toString()).toList() ?? [],
      sizes: (json['sizes'] as List?)?.map((s) => s.toString()).toList() ?? [],
      features:
          (json['features'] as List?)?.map((f) => f.toString()).toList() ?? [],
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }
}
