import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<Category>> getCategories();
  Future<List<Category>> getSubcategories(String parentId);
  Future<List<Product>> getFeaturedProducts({int limit});
  Future<List<Product>> getProductsByCategory(String categoryId);
  Future<List<Product>> searchProducts({
    String? query,
    double? minPrice,
    double? maxPrice,
    String? categoryId,
    String? sortBy,
  });
  Future<Product> getProductById(String id);
  Future<Product> getProductBySlug(String slug);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final http.Client client;

  ProductRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Category>> getCategories() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.categories}'),
        headers: ApiConstants.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          'Failed to load categories: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<List<Category>> getSubcategories(String parentId) async {
    try {
      final response = await client.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.categories}/sub/$parentId',
        ),
        headers: ApiConstants.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          'Failed to load subcategories: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      final response = await client.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.featured}?limit=$limit',
        ),
        headers: ApiConstants.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          'Failed to load featured products: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await client.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.products}/category/$categoryId',
        ),
        headers: ApiConstants.headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        final List<dynamic> products = result['products'] ?? [];
        return products.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          'Failed to load products by category: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<List<Product>> searchProducts({
    String? query,
    double? minPrice,
    double? maxPrice,
    String? categoryId,
    String? sortBy,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.search}')
          .replace(
            queryParameters: {
              if (query != null) 'search': query,
              if (minPrice != null) 'minPrice': minPrice.toString(),
              if (maxPrice != null) 'maxPrice': maxPrice.toString(),
              if (categoryId != null) 'categoryId': categoryId,
              if (sortBy != null) 'sortBy': sortBy,
            },
          );

      final response = await client.get(uri, headers: ApiConstants.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        final List<dynamic> products = result['products'] ?? [];
        return products.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          'Failed to search products: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.products}/$id'),
        headers: ApiConstants.headers,
      );

      if (response.statusCode == 200) {
        return ProductModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<Product> getProductBySlug(String slug) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.products}/slug/$slug'),
        headers: ApiConstants.headers,
      );

      if (response.statusCode == 200) {
        return ProductModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }
}
