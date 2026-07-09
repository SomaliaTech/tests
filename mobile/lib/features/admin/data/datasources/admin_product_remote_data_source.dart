// lib/features/admin/data/datasources/admin_product_remote_data_source_impl.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/admin_product_model.dart';
import 'package:mobile/features/admin/data/models/color_model.dart';
import 'package:mobile/features/admin/data/models/size_model.dart';

abstract class AdminProductRemoteDataSource {
  Future<List<AdminProductModel>> getAllProducts();
  Future<AdminProductModel> getProductById(String productId);

  // ✅ ADD the 'images' named parameter here
  Future<String> createProduct(
    Map<String, dynamic> productData, {
    List<File> images, // ✅ This must be here
  });

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updateData, {
    List<File> newImages,
    List<String> deletedImageIds,
    List<Map<String, dynamic>> existingVariants,
    List<Map<String, dynamic>> newVariants,
    List<String> deletedVariantIds,
  });

  Future<void> deleteProduct(String productId);
  Future<List<AdminCategoryModel>> getCategoriesTree();
  Future<List<ColorModel>> getColors();
  Future<List<SizeModel>> getSizes();
  Future<void> uploadProductImage(String productId, String base64Image);
  Future<void> addProductVariant(
    String productId,
    Map<String, dynamic> variantData,
  );
}

class AdminProductRemoteDataSourceImpl implements AdminProductRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  AdminProductRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<String> _getToken() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw ServerException('Token not found');
    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {'Authorization': 'Bearer $token'};
  }

  @override
  Future<List<AdminProductModel>> getAllProducts() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/products/list'),
      headers: {...headers, 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => AdminProductModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load products: ${response.statusCode}');
    }
  }

  @override
  Future<AdminProductModel> getProductById(String productId) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/products/$productId'),
      headers: {...headers, 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AdminProductModel.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw ServerException('Product not found');
    } else {
      throw ServerException('Failed to load product: ${response.statusCode}');
    }
  }

  // ✅ Multipart create product with images
  @override
  Future<String> createProduct(
    Map<String, dynamic> productData, {
    List<File> images = const [],
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConstants.baseUrl}/admin/products');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = headers['Authorization']!;
    request.fields['data'] = json.encode(productData);

    debugPrint('📤 [DataSource] Creating product with ${images.length} images');

    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      if (await image.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            image.path,
            filename: 'image_$i.jpg',
          ),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('📡 Create Response Status: ${response.statusCode}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'] ?? data['product']?['id'] ?? '';
    } else {
      debugPrint('❌ Create failed: ${response.statusCode}');
      debugPrint('   Response: ${response.body}');
      throw ServerException('Failed to create product: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updateData, {
    List<File> newImages = const [],
    List<String> deletedImageIds = const [],
    List<Map<String, dynamic>> existingVariants = const [],
    List<Map<String, dynamic>> newVariants = const [],
    List<String> deletedVariantIds = const [],
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConstants.baseUrl}/admin/products/$productId');

    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = headers['Authorization']!;

    final dataMap = {
      ...updateData,
      'deleted_image_ids': deletedImageIds,
      'deleted_variant_ids': deletedVariantIds,
      'existing_variants': existingVariants,
      'new_variants': newVariants,
    };

    request.fields['data'] = json.encode(dataMap);

    for (int i = 0; i < newImages.length; i++) {
      final image = newImages[i];
      if (await image.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            image.path,
            filename: 'image_$i.jpg',
          ),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException('Failed to update product: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse('${ApiConstants.baseUrl}/admin/products/$productId'),
      headers: {...headers, 'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ServerException('Failed to delete product: ${response.statusCode}');
    }
  }

  @override
  Future<List<AdminCategoryModel>> getCategoriesTree() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/categories/tree'),
      headers: {...headers, 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => AdminCategoryModel.fromJson(json)).toList();
    } else {
      throw ServerException(
        'Failed to load categories: ${response.statusCode}',
      );
    }
  }

  @override
  Future<List<ColorModel>> getColors() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/colors/all'),
      headers: {...headers, 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ColorModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load colors: ${response.statusCode}');
    }
  }

  @override
  Future<List<SizeModel>> getSizes() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/sizes/all'),
      headers: {...headers, 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => SizeModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load sizes: ${response.statusCode}');
    }
  }

  @override
  Future<void> uploadProductImage(String productId, String base64Image) async {
    final headers = await _getHeaders();
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/products/$productId/images'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: json.encode({'image': base64Image}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException('Failed to upload image: ${response.statusCode}');
    }
  }

  @override
  Future<void> addProductVariant(
    String productId,
    Map<String, dynamic> variantData,
  ) async {
    final headers = await _getHeaders();
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/products/$productId/variants'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: json.encode(variantData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException('Failed to add variant: ${response.statusCode}');
    }
  }
}
