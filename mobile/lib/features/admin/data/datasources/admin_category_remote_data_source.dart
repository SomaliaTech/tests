// lib/features/admin/data/datasources/admin_category_remote_data_source.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/admin_product_model.dart';
import 'package:flutter/foundation.dart';

abstract class AdminCategoryRemoteDataSource {
  Future<List<AdminCategoryModel>> getCategoriesTree();
  Future<List<AdminCategoryModel>> getAllCategories();
  Future<void> createCategory(Map<String, dynamic> data);
  Future<void> updateCategory(String categoryId, Map<String, dynamic> data);
  Future<void> deleteCategory(String categoryId);
  Future<void> deleteCategoryWithTransfer(
    String categoryId,
    String targetCategoryId,
  );
}

class AdminCategoryRemoteDataSourceImpl
    implements AdminCategoryRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  AdminCategoryRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<String> _getToken() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw const ServerException('Token not found');
    return token;
  }

  @override
  Future<List<AdminCategoryModel>> getCategoriesTree() async {
    if (kDebugMode) debugPrint('🔍 [AdminCategories] Fetching categories tree');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/categories/tree';

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode)
        debugPrint(
          '📡 [AdminCategories] Response Status: ${response.statusCode}',
        );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map(
              (json) =>
                  AdminCategoryModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [AdminCategories] Error: $e');
      rethrow;
    }
  }

  @override
  Future<List<AdminCategoryModel>> getAllCategories() async {
    if (kDebugMode)
      debugPrint('🔍 [AdminCategories] Fetching all categories flat list');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/categories/tree';

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final categories = jsonList
            .map(
              (json) =>
                  AdminCategoryModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        final flatList = <AdminCategoryModel>[];
        _flattenCategories(categories, flatList);

        if (kDebugMode)
          debugPrint(
            '✅ [AdminCategories] Found ${flatList.length} categories (flattened)',
          );
        return flatList;
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [AdminCategories] Error: $e');
      rethrow;
    }
  }

  void _flattenCategories(
    List<AdminCategoryModel> categories,
    List<AdminCategoryModel> result,
  ) {
    for (final category in categories) {
      result.add(category);
      if (category.children.isNotEmpty) {
        _flattenCategories(
          category.children as List<AdminCategoryModel>,
          result,
        );
      }
    }
  }

  @override
  Future<void> createCategory(Map<String, dynamic> data) async {
    if (kDebugMode) debugPrint('🔍 [AdminCategories] Creating category: $data');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/categories';

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (kDebugMode)
        debugPrint(
          '📡 [AdminCategories] Create Response: ${response.statusCode}',
        );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [AdminCategories] Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    if (kDebugMode)
      debugPrint('🔍 [AdminCategories] Updating category: $categoryId');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/categories/$categoryId';

      final response = await client.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    if (kDebugMode)
      debugPrint('🔍 [AdminCategories] Deleting category: $categoryId');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/categories/$categoryId';

      final response = await client.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode)
        debugPrint(
          '📡 [AdminCategories] Delete Response Status: ${response.statusCode}',
        );
      if (kDebugMode)
        debugPrint(
          '📡 [AdminCategories] Delete Response Body: ${response.body}',
        );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        if (kDebugMode)
          debugPrint(
            '❌ [AdminCategories] Delete Error: ${errorBody['message']}',
          );
        throw ServerException(
          errorBody['message'] ?? 'Failed: ${response.statusCode}',
        );
      }

      if (kDebugMode)
        debugPrint('✅ [AdminCategories] Category deleted successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [AdminCategories] Delete Exception: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteCategoryWithTransfer(
    String categoryId,
    String targetCategoryId,
  ) async {
    if (kDebugMode)
      debugPrint(
        '🔍 [AdminCategories] Deleting category $categoryId with transfer to $targetCategoryId',
      );
    try {
      final token = await _getToken();
      final url =
          '${ApiConstants.baseUrl}/admin/categories/$categoryId?transferToId=$targetCategoryId';

      final response = await client.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode)
        debugPrint(
          '📡 [AdminCategories] Delete Transfer Response: ${response.statusCode}',
        );
      if (kDebugMode)
        debugPrint(
          '📡 [AdminCategories] Delete Transfer Body: ${response.body}',
        );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          errorBody['message'] ?? 'Failed: ${response.statusCode}',
        );
      }

      if (kDebugMode)
        debugPrint('✅ [AdminCategories] Category deleted with transfer');
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ [AdminCategories] Delete Transfer Error: $e');
      rethrow;
    }
  }
}
