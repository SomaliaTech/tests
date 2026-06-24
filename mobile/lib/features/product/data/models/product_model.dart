import '../../domain/entities/product.dart';

class ProductModel {
  // No private constructor needed

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

    // Parse variants and extract unique colors/sizes from nested objects
    List<ProductVariant> parsedVariants = [];
    Set<String> uniqueColors = {};
    Set<String> uniqueSizes = {};

    final variantsData = json['variants'];
    if (variantsData != null && variantsData is List) {
      parsedVariants = variantsData.map((v) {
        // Backend returns nested 'color' and 'size' objects
        final colorObj = v['color'];
        final colorName = colorObj is Map ? colorObj['name'] as String? : null;

        final sizeObj = v['size'];
        final sizeName = sizeObj is Map ? sizeObj['name'] as String? : null;

        // Add to unique sets so the UI knows what options to show
        if (colorName != null && colorName.isNotEmpty)
          uniqueColors.add(colorName);
        if (sizeName != null && sizeName.isNotEmpty) uniqueSizes.add(sizeName);

        return ProductVariant(
          id: v['id'] as String? ?? '',
          colorName: colorName,
          sizeName: sizeName,
          price: parsePrice(v['price']),
          stock: v['stock'] as int? ?? 0,
        );
      }).toList();
    }

    // Extract category name from nested object
    final categoryObj = json['category'];
    final categoryName = categoryObj is Map
        ? categoryObj['name'] as String?
        : null;

    // Extract features (fallback to parsing 'tags' string if 'features' list is missing)
    List<String> parsedFeatures = [];
    if (json['features'] is List) {
      parsedFeatures = (json['features'] as List)
          .map((f) => f.toString())
          .toList();
    } else if (json['tags'] is String && (json['tags'] as String).isNotEmpty) {
      parsedFeatures = (json['tags'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
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
      categoryName: categoryName,
      brand: json['brand'] as String?,
      imageUrls: parseImages(json['images']),
      variants: parsedVariants,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      colors: uniqueColors.toList(),
      sizes: uniqueSizes.toList(),
      features: parsedFeatures,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }
}
