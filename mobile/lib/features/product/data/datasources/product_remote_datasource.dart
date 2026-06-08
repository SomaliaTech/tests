import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> getFeaturedProducts({int limit});
  Future<List<ProductModel>> getProductsByCategory(String categoryId);
  Future<List<ProductModel>> searchProducts({
    String? query,
    double? minPrice,
    double? maxPrice,
    String? categoryId,
    String? sortBy,
  });
  Future<ProductModel> getProductById(String id);
  Future<ProductModel> getProductBySlug(String slug);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final http.Client client;

  ProductRemoteDataSourceImpl({required this.client});
  @override
  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
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
        throw ServerException('Failed to load featured products');
      }
    } catch (e) {
      print('Error fetching featured products: $e');
      throw ServerException('Failed to load featured products: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
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
        throw ServerException('Failed to load products by category');
      }
    } catch (e) {
      print('Error fetching products by category: $e');
      throw ServerException('Failed to load products by category: $e');
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.categories}'),
      headers: ApiConstants.headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load categories');
    }
  }

  // @override
  // Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
  //   final response = await client.get(
  //     Uri.parse('${ApiConstants.baseUrl}${ApiConstants.featured}?limit=$limit'),
  //     headers: ApiConstants.headers,
  //   );

  //   if (response.statusCode == 200) {
  //     final List<dynamic> jsonList = json.decode(response.body);
  //     return jsonList.map((json) => ProductModel.fromJson(json)).toList();
  //   } else {
  //     throw ServerException('Failed to load featured products');
  //   }
  // }

  // @override
  // Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
  //   final response = await client.get(
  //     Uri.parse(
  //       '${ApiConstants.baseUrl}${ApiConstants.products}/category/$categoryId',
  //     ),
  //     headers: ApiConstants.headers,
  //   );

  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic> result = json.decode(response.body);
  //     final List<dynamic> products = result['products'] ?? [];
  //     return products.map((json) => ProductModel.fromJson(json)).toList();
  //   } else {
  //     throw ServerException('Failed to load products by category');
  //   }
  // }

  @override
  Future<List<ProductModel>> searchProducts({
    String? query,
    double? minPrice,
    double? maxPrice,
    String? categoryId,
    String? sortBy,
  }) async {
    final Uri uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.search}')
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
      throw ServerException('Failed to search products');
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.products}/$id'),
      headers: ApiConstants.headers,
    );

    if (response.statusCode == 200) {
      return ProductModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException('Failed to load product');
    }
  }

  @override
  Future<ProductModel> getProductBySlug(String slug) async {
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.products}/slug/$slug'),
      headers: ApiConstants.headers,
    );

    if (response.statusCode == 200) {
      return ProductModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException('Failed to load product');
    }
  }
}
