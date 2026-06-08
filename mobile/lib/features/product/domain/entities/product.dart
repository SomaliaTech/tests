class Product {
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
  });

  // Factory method to safely parse price from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    // Safe price parsing
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    // Safe image parsing
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

    // Safe variants parsing
    List<ProductVariant> parseVariants(dynamic variantsData) {
      if (variantsData == null) return [];
      if (variantsData is List) {
        return variantsData.map((v) => ProductVariant.fromJson(v)).toList();
      }
      return [];
    }

    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: parsePrice(json['price']),
      stock: json['stock'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      categoryId: json['categoryId'] as String? ?? '',
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

class ProductVariant {
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

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return ProductVariant(
      id: json['id'] as String? ?? '',
      colorName: json['colorName'] as String?,
      sizeName: json['sizeName'] as String?,
      price: parsePrice(json['price']),
      stock: json['stock'] as int? ?? 0,
    );
  }
}
