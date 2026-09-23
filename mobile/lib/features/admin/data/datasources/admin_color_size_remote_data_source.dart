import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/color_model.dart';
import 'package:mobile/features/admin/data/models/size_model.dart';
import 'package:flutter/foundation.dart';

abstract class AdminColorSizeRemoteDataSource {
  Future<List<ColorModel>> getAllColors();
  Future<void> createColor(Map<String, dynamic> data);
  Future<void> updateColor(String colorId, Map<String, dynamic> data);
  Future<void> deleteColor(String colorId);

  Future<List<SizeModel>> getAllSizes();
  Future<void> createSize(Map<String, dynamic> data);
  Future<void> updateSize(String sizeId, Map<String, dynamic> data);
  Future<void> deleteSize(String sizeId);
}

class AdminColorSizeRemoteDataSourceImpl
    implements AdminColorSizeRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  AdminColorSizeRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<String> _getToken() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw const ServerException('Token not found');
    return token;
  }

  // ==========================================
  // COLORS
  // ==========================================
  @override
  Future<List<ColorModel>> getAllColors() async {
    if (kDebugMode) debugPrint('🔍 [AdminColors] Fetching all colors');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/colors/all';

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode)
        debugPrint('📡 [AdminColors] Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ColorModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [AdminColors] Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> createColor(Map<String, dynamic> data) async {
    if (kDebugMode) debugPrint('🔍 [AdminColors] Creating color: $data');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/colors';

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (kDebugMode)
        debugPrint('📡 [AdminColors] Create Response: ${response.statusCode}');

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [AdminColors] Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateColor(String colorId, Map<String, dynamic> data) async {
    if (kDebugMode) debugPrint('🔍 [AdminColors] Updating color: $colorId');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/colors/$colorId';

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
  Future<void> deleteColor(String colorId) async {
    if (kDebugMode) debugPrint('🔍 [AdminColors] Deleting color: $colorId');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/colors/$colorId';

      final response = await client.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          errorBody['message'] ?? 'Failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // SIZES
  // ==========================================
  @override
  Future<List<SizeModel>> getAllSizes() async {
    if (kDebugMode) debugPrint('🔍 [AdminSizes] Fetching all sizes');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/sizes/all';

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode)
        debugPrint('📡 [AdminSizes] Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => SizeModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [AdminSizes] Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> createSize(Map<String, dynamic> data) async {
    if (kDebugMode) debugPrint('🔍 [AdminSizes] Creating size: $data');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/sizes';

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (kDebugMode)
        debugPrint('📡 [AdminSizes] Create Response: ${response.statusCode}');

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [AdminSizes] Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateSize(String sizeId, Map<String, dynamic> data) async {
    if (kDebugMode) debugPrint('🔍 [AdminSizes] Updating size: $sizeId');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/sizes/$sizeId';

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
  Future<void> deleteSize(String sizeId) async {
    if (kDebugMode) debugPrint('🔍 [AdminSizes] Deleting size: $sizeId');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/sizes/$sizeId';

      final response = await client.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          errorBody['message'] ?? 'Failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
