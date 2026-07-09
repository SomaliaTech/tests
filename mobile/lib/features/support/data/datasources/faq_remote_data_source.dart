import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/support/data/models/faq_model.dart';

abstract class FaqRemoteDataSource {
  Future<List<FaqModel>> getActiveFaqs();
  Future<List<FaqModel>> getAllFaqs();
  Future<List<FaqModel>> getFaqsByCategory(String category);
  Future<List<String>> getFaqCategories();
  Future<FaqModel> getFaqById(String id);
  Future<FaqModel> createFaq(Map<String, dynamic> faqData);
  Future<FaqModel> updateFaq(String id, Map<String, dynamic> faqData);
  Future<void> deleteFaq(String id);
  Future<FaqModel> toggleFaqStatus(String id);
  Future<void> reorderFaqs(List<String> faqIds);
}

class FaqRemoteDataSourceImpl implements FaqRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  FaqRemoteDataSourceImpl({required this.client, required this.storageService});

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
      const wrapperKeys = ['faqs', 'data', 'items', 'results', 'faq'];
      for (final key in wrapperKeys) {
        if (response.containsKey(key) && response[key] is List) {
          return response[key];
        }
      }

      print(
        '⚠️ [FAQ] Could not extract list from map with keys: ${response.keys}',
      );
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
  Future<List<FaqModel>> getActiveFaqs() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/faq/active'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📦 [FAQ] Active Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('📦 [FAQ] Active response type: ${decoded.runtimeType}');

        final jsonList = _extractList(decoded, preferredKey: 'faqs');
        print('✅ [FAQ] Found ${jsonList.length} active FAQs');

        return jsonList
            .map((json) => FaqModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException('Failed to load FAQs: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FAQ] Error loading active FAQs: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<List<FaqModel>> getAllFaqs() async {
    try {
      final token = await _getToken();
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/faq'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📦 [FAQ] All Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('📦 [FAQ] All response type: ${decoded.runtimeType}');

        // Debug: Print keys if it's a map
        if (decoded is Map) {
          print('📦 [FAQ] Map keys: ${decoded.keys}');
        }

        final jsonList = _extractList(decoded, preferredKey: 'faqs');
        print('✅ [FAQ] Found ${jsonList.length} FAQs');

        return jsonList
            .map((json) => FaqModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException('Failed to load FAQs: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FAQ] Error loading all FAQs: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<List<FaqModel>> getFaqsByCategory(String category) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/faq/category/$category'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final jsonList = _extractList(decoded, preferredKey: 'faqs');

        return jsonList
            .map((json) => FaqModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Failed to load FAQs by category: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<List<String>> getFaqCategories() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/faq/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList();
        } else if (decoded is Map && decoded.containsKey('categories')) {
          final categories = decoded['categories'];
          if (categories is List) {
            return categories.map((item) => item.toString()).toList();
          }
        }
        return [];
      } else {
        throw ServerException(
          'Failed to load FAQ categories: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<FaqModel> getFaqById(String id) async {
    try {
      final token = await _getToken();
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/faq/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = _extractObject(decoded, preferredKey: 'faq') ?? decoded;
        return FaqModel.fromJson(data);
      } else {
        throw ServerException('Failed to load FAQ: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<FaqModel> createFaq(Map<String, dynamic> faqData) async {
    try {
      final token = await _getToken();
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/faq'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(faqData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = _extractObject(decoded, preferredKey: 'faq') ?? decoded;
        return FaqModel.fromJson(data);
      } else {
        throw ServerException(
          'Failed to create FAQ: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<FaqModel> updateFaq(String id, Map<String, dynamic> faqData) async {
    try {
      final token = await _getToken();
      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}/faq/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(faqData),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = _extractObject(decoded, preferredKey: 'faq') ?? decoded;
        return FaqModel.fromJson(data);
      } else {
        throw ServerException('Failed to update FAQ: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<void> deleteFaq(String id) async {
    try {
      final token = await _getToken();
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}/faq/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Failed to delete FAQ: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<FaqModel> toggleFaqStatus(String id) async {
    try {
      final token = await _getToken();
      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}/faq/$id/toggle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = _extractObject(decoded, preferredKey: 'faq') ?? decoded;
        return FaqModel.fromJson(data);
      } else {
        throw ServerException(
          'Failed to toggle FAQ status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<void> reorderFaqs(List<String> faqIds) async {
    try {
      final token = await _getToken();
      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}/faq/reorder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'faqIds': faqIds}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Failed to reorder FAQs: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }
}
