import 'dart:convert';
import 'dart:io';
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
  Future<String> createProduct(Map<String, dynamic> productData);
  Future<void> updateProduct(String productId, Map<String, dynamic> updateData);
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

  @override
  Future<List<AdminProductModel>> getAllProducts() async {
    print('🔍 [AdminProducts] Fetching all products');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/products/all';

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 [AdminProducts] Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((json) => AdminProductModel.fromJson(json))
            .toList();
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AdminProducts] Error: $e');
      rethrow;
    }
  }

  @override
  Future<AdminProductModel> getProductById(String productId) async {
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/products/$productId';

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return AdminProductModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> createProduct(Map<String, dynamic> productData) async {
    print('🔍 [AdminProducts] Creating product');

    // ✅ FILTER: Clean variant data if included
    if (productData['variants'] != null) {
      final List<dynamic> variants = productData['variants'];
      productData['variants'] = variants.map((v) {
        final variantMap = v as Map<String, dynamic>;
        final cleanVariant = {
          'colorId': variantMap['colorId'],
          'sizeId': variantMap['sizeId'],
          'sku': variantMap['sku'],
          'stock': variantMap['stock'],
          'price': variantMap['price'],
        };
        cleanVariant.removeWhere((key, value) => value == null);
        return cleanVariant;
      }).toList();
    }

    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/products';

      print('📤 [AdminProducts] Clean product data: $productData');

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(productData),
      );

      print('📡 [AdminProducts] Create Response: ${response.statusCode}');
      print('📦 [AdminProducts] Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'] ?? '';
      } else {
        try {
          final errorData = json.decode(response.body);
          print('❌ [AdminProducts] Error details: $errorData');
          throw ServerException(
            'Failed: ${errorData['message'] ?? response.statusCode}',
          );
        } catch (e) {
          throw ServerException('Failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ [AdminProducts] Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/products/$productId';

      final response = await client.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/products/$productId';

      final response = await client.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<AdminCategoryModel>> getCategoriesTree() async {
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
        return jsonList
            .map((json) => AdminCategoryModel.fromJson(json))
            .toList();
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ColorModel>> getColors() async {
    print('🔍 [AdminProducts] Fetching colors');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/colors';

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ColorModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AdminProducts] Error: $e');
      rethrow;
    }
  }

  @override
  Future<List<SizeModel>> getSizes() async {
    print('🔍 [AdminProducts] Fetching sizes');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/sizes';

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => SizeModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AdminProducts] Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> uploadProductImage(String productId, String base64Image) async {
    print('🔍 [AdminProducts] Uploading image for product: $productId');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/products/$productId/images/base64';

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'base64Image': base64Image}),
      );

      print('📡 [AdminProducts] Image upload response: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AdminProducts] Image upload error: $e');
      rethrow;
    }
  }

  @override
  Future<void> addProductVariant(
    String productId,
    Map<String, dynamic> variantData,
  ) async {
    print('🔍 [AdminProducts] Adding variant to product: $productId');

    // ✅ FILTER: Only send fields the backend expects
    final cleanVariantData = {
      'colorId': variantData['colorId'],
      'sizeId': variantData['sizeId'],
      'sku': variantData['sku'],
      'stock': variantData['stock'],
      'price': variantData['price'],
    };

    // Remove null values (backend doesn't like null for optional fields)
    cleanVariantData.removeWhere((key, value) => value == null);

    print('📤 [AdminProducts] Clean variant data: $cleanVariantData');

    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/products/$productId/variants';

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(cleanVariantData),
      );

      print('📡 [AdminProducts] Variant response: ${response.statusCode}');
      print('📦 [AdminProducts] Variant response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        try {
          final errorData = json.decode(response.body);
          print('❌ [AdminProducts] Error details: $errorData');
          throw ServerException(
            'Failed to add variant: ${errorData['message'] ?? response.statusCode}',
          );
        } catch (e) {
          throw ServerException(
            'Failed to add variant: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      print('❌ [AdminProducts] Variant error: $e');
      rethrow;
    }
  }
}
