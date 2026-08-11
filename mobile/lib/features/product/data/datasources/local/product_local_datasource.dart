// lib/features/product/data/datasources/local/product_local_datasource.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobile/features/product/data/models/product_model.dart';
import 'package:mobile/features/product/domain/entities/product.dart';

abstract class ProductLocalDataSource {
  Future<List<Product>> getCachedFeaturedProducts();
  Future<void> cacheFeaturedProducts(List<Product> products);
  Future<List<Product>> getCachedProductsByCategory(String categoryId);
  Future<void> cacheProductsByCategory(
    String categoryId,
    List<Product> products,
  );
  Future<Product?> getCachedProduct(String productId);
  Future<void> cacheProduct(Product product);
  Future<void> clearCache();
  Future<List<Product>> getCachedLatestProducts();
  Future<void> cacheLatestProducts(List<Product> products);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  static const String _productBox = 'product_cache';
  static const String _featuredKey = 'featured_products';
  static const String _latestKey =
      'latest_products'; // ✅ Consistent naming with _featuredKey

  Box<String> get _box => Hive.box<String>(_productBox);

  // ✅ FIXED: Use Hive instead of non-existent sharedPreferences
  @override
  Future<List<Product>> getCachedLatestProducts() async {
    try {
      final jsonString = _box.get(_latestKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Error reading cached latest products: $e');
    }
    return [];
  }

  // ✅ FIXED: Use Hive and reuse _productToJson helper
  @override
  Future<void> cacheLatestProducts(List<Product> products) async {
    try {
      final jsonList = products.map((p) => _productToJson(p)).toList();
      await _box.put(_latestKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('❌ Error caching latest products: $e');
    }
  }

  @override
  Future<List<Product>> getCachedFeaturedProducts() async {
    try {
      final jsonString = _box.get(_featuredKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Error reading cached featured products: $e');
    }
    return [];
  }

  @override
  Future<void> cacheFeaturedProducts(List<Product> products) async {
    try {
      final jsonList = products.map((p) => _productToJson(p)).toList();
      await _box.put(_featuredKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('❌ Error caching featured products: $e');
    }
  }

  @override
  Future<List<Product>> getCachedProductsByCategory(String categoryId) async {
    try {
      final jsonString = _box.get('category_products_$categoryId');
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint(
        '❌ Error reading cached products for category $categoryId: $e',
      );
    }
    return [];
  }

  @override
  Future<void> cacheProductsByCategory(
    String categoryId,
    List<Product> products,
  ) async {
    try {
      final jsonList = products.map((p) => _productToJson(p)).toList();
      await _box.put('category_products_$categoryId', json.encode(jsonList));
    } catch (e) {
      debugPrint('❌ Error caching products for category $categoryId: $e');
    }
  }

  @override
  Future<Product?> getCachedProduct(String productId) async {
    try {
      final jsonString = _box.get('product_$productId');
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        return ProductModel.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('❌ Error reading cached product $productId: $e');
    }
    return null;
  }

  @override
  Future<void> cacheProduct(Product product) async {
    try {
      final jsonMap = _productToJson(product);
      await _box.put('product_${product.id}', json.encode(jsonMap));
    } catch (e) {
      debugPrint('❌ Error caching product ${product.id}: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    await _box.clear();
    debugPrint('🗑️ Product cache cleared');
  }

  Map<String, dynamic> _productToJson(Product product) {
    return {
      'id': product.id,
      'name': product.name,
      'slug': product.slug,
      'description': product.description,
      'price': product.price,
      'stock': product.stock,
      'isActive': product.isActive,
      'categoryId': product.categoryId,
      if (product.categoryName != null) 'categoryName': product.categoryName,
      if (product.brand != null) 'brand': product.brand,
      'imageUrls': product.imageUrls,
      'variants': product.variants
          .map(
            (v) => {
              'id': v.id,
              if (v.colorName != null) 'colorName': v.colorName,
              if (v.sizeName != null) 'sizeName': v.sizeName,
              'price': v.price,
              'stock': v.stock,
            },
          )
          .toList(),
      'colors': product.colors,
      'sizes': product.sizes,
      'features': product.features,
      'rating': product.rating,
      'reviewCount': product.reviewCount,
      'createdAt': product.createdAt.toIso8601String(),
    };
  }
}
