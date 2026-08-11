import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/product/data/models/banner_model.dart';

abstract class BannerRemoteDataSource {
  Future<List<BannerModel>> getActiveBanners();
  Future<List<BannerModel>> getAllBanners();
  Future<BannerModel> getBannerById(String id);
  Future<BannerModel> createBanner(Map<String, dynamic> bannerData);
  Future<BannerModel> updateBanner(String id, Map<String, dynamic> bannerData);
  Future<void> deleteBanner(String id);
  Future<BannerModel> toggleBannerStatus(String id);
  Future<void> reorderBanners(List<String> bannerIds);
  // Add to BannerRemoteDataSource abstract class
  Future<Map<String, dynamic>> uploadBannerImage({
    required String base64Image,
    required String fileName,
  });
}

class BannerRemoteDataSourceImpl implements BannerRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  BannerRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<String> _getToken() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw const ServerException('Token not found');
    return token;
  }

  /// Helper method to extract list from various API response formats
  List<dynamic> _extractList(dynamic response, {String? preferredKey}) {
    if (response is List) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      // Check preferred key first
      if (preferredKey != null &&
          response.containsKey(preferredKey) &&
          response[preferredKey] is List) {
        return response[preferredKey];
      }

      // Check common wrapper keys
      const wrapperKeys = ['banners', 'data', 'items', 'results'];
      for (final key in wrapperKeys) {
        if (response.containsKey(key) && response[key] is List) {
          return response[key];
        }
      }

      print('⚠️ Could not extract list from map with keys: ${response.keys}');
    }

    return [];
  }

  /// Helper method to extract single object from various API response formats
  Map<String, dynamic>? _extractObject(
    dynamic response, {
    String? preferredKey,
  }) {
    if (response is Map<String, dynamic>) {
      if (preferredKey != null &&
          response.containsKey(preferredKey) &&
          response[preferredKey] is Map<String, dynamic>) {
        return response[preferredKey];
      }
      return response;
    }
    return null;
  }

  @override
  Future<List<BannerModel>> getActiveBanners() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/banners/active'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📦 [Banners] Active Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('📦 [Banners] Active response type: ${decoded.runtimeType}');

        final jsonList = _extractList(decoded, preferredKey: 'banners');
        print('✅ [Banners] Found ${jsonList.length} active banners');

        return jsonList
            .map((json) => BannerModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException('Failed to load banners: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [Banners] Error loading active banners: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<List<BannerModel>> getAllBanners() async {
    try {
      final token = await _getToken();
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/banners'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📦 [Banners] All Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('📦 [Banners] All response type: ${decoded.runtimeType}');

        // Debug: Print keys if it's a map
        if (decoded is Map) {
          print('📦 [Banners] Map keys: ${decoded.keys}');
        }

        final jsonList = _extractList(decoded, preferredKey: 'banners');
        print('✅ [Banners] Found ${jsonList.length} banners');

        return jsonList
            .map((json) => BannerModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException('Failed to load banners: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [Banners] Error loading all banners: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<BannerModel> getBannerById(String id) async {
    try {
      final token = await _getToken();
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/banners/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = _extractObject(decoded, preferredKey: 'banner') ?? decoded;
        return BannerModel.fromJson(data);
      } else {
        throw ServerException('Failed to load banner: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<BannerModel> createBanner(Map<String, dynamic> bannerData) async {
    try {
      final token = await _getToken();
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/banners'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bannerData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = _extractObject(decoded, preferredKey: 'banner') ?? decoded;
        return BannerModel.fromJson(data);
      } else {
        throw ServerException(
          'Failed to create banner: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<BannerModel> updateBanner(
    String id,
    Map<String, dynamic> bannerData,
  ) async {
    try {
      final token = await _getToken();
      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}/banners/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bannerData),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = _extractObject(decoded, preferredKey: 'banner') ?? decoded;
        return BannerModel.fromJson(data);
      } else {
        throw ServerException(
          'Failed to update banner: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<void> deleteBanner(String id) async {
    try {
      final token = await _getToken();
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}/banners/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          'Failed to delete banner: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<BannerModel> toggleBannerStatus(String id) async {
    try {
      final token = await _getToken();
      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}/banners/$id/toggle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = _extractObject(decoded, preferredKey: 'banner') ?? decoded;
        return BannerModel.fromJson(data);
      } else {
        throw ServerException(
          'Failed to toggle banner status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  // Add this to your BannerRemoteDataSourceImpl class
  @override
  Future<Map<String, dynamic>> uploadBannerImage({
    required String base64Image,
    required String fileName,
  }) async {
    try {
      final token = await _getToken();
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/banners/upload-image'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'image': base64Image, 'fileName': fileName}),
      );

      print('📦 [Banner Upload] Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        print('✅ [Banner Upload] Image uploaded successfully');
        return decoded;
      } else {
        print('❌ [Banner Upload] Error: ${response.body}');
        throw ServerException('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [Banner Upload] Exception: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<void> reorderBanners(List<String> bannerIds) async {
    try {
      final token = await _getToken();
      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}/banners/reorder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'bannerIds': bannerIds}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          'Failed to reorder banners: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }
}
