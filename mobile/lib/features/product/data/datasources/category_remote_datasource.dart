import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/category.dart';
import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<Category>> getCategories();
  Future<List<Category>> getParentCategories();
  Future<List<Category>> getSubcategories(String parentId);
  Future<Category> getCategoryById(String id);
  Future<Category> getCategoryBySlug(String slug);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final http.Client client;

  CategoryRemoteDataSourceImpl({required this.client});

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
  Future<List<Category>> getParentCategories() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.categories}/parents'),
        headers: ApiConstants.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          'Failed to load parent categories: ${response.statusCode}',
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
  Future<Category> getCategoryById(String id) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.categories}/$id'),
        headers: ApiConstants.headers,
      );

      if (response.statusCode == 200) {
        return CategoryModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException(
          'Failed to load category: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<Category> getCategoryBySlug(String slug) async {
    try {
      final response = await client.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.categories}/slug/$slug',
        ),
        headers: ApiConstants.headers,
      );

      if (response.statusCode == 200) {
        return CategoryModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException(
          'Failed to load category: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }
}
