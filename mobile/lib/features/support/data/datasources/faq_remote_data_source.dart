import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/support/data/models/faq_model.dart';
import 'dart:developer' as developer;

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
    if (token == null) {
      developer.log('❌ [FAQ] No auth token found', name: 'FAQ');
      throw const ServerException('Token not found');
    }
    developer.log(
      '✅ [FAQ] Token retrieved: ${token.substring(0, min(20, token.length))}...',
      name: 'FAQ',
    );
    return token;
  }

  /// Helper method to extract list from various API response formats
  List<dynamic> _extractList(dynamic response, {String? preferredKey}) {
    developer.log(
      '📦 [FAQ] _extractList called with type: ${response.runtimeType}',
      name: 'FAQ',
    );

    if (response is List) {
      developer.log(
        '📦 [FAQ] Response is direct List with ${response.length} items',
        name: 'FAQ',
      );
      return response;
    }

    if (response is Map<String, dynamic>) {
      developer.log(
        '📦 [FAQ] Response is Map with keys: ${response.keys}',
        name: 'FAQ',
      );

      // Check preferred key first
      if (preferredKey != null &&
          response.containsKey(preferredKey) &&
          response[preferredKey] is List) {
        final list = response[preferredKey] as List;
        developer.log(
          '📦 [FAQ] Found list in preferred key "$preferredKey" with ${list.length} items',
          name: 'FAQ',
        );
        return list;
      }

      // Check common wrapper keys
      const wrapperKeys = [
        'faqs',
        'data',
        'items',
        'results',
        'faq',
        'faqsData',
      ];
      for (final key in wrapperKeys) {
        if (response.containsKey(key) && response[key] is List) {
          final list = response[key] as List;
          developer.log(
            '📦 [FAQ] Found list in wrapper key "$key" with ${list.length} items',
            name: 'FAQ',
          );
          return list;
        }
      }

      // Check if there's a 'success' or 'status' field (common API pattern)
      if (response.containsKey('success') || response.containsKey('status')) {
        developer.log(
          '📦 [FAQ] Response has success/status field: ${response['success'] ?? response['status']}',
          name: 'FAQ',
        );
      }

      developer.log(
        '⚠️ [FAQ] Could not extract list from map with keys: ${response.keys}',
        name: 'FAQ',
      );

      // Try to see if any value is a list
      for (final entry in response.entries) {
        if (entry.value is List) {
          developer.log(
            '📦 [FAQ] Found List in key "${entry.key}" with ${(entry.value as List).length} items',
            name: 'FAQ',
          );
          return entry.value;
        }
      }
    }

    developer.log('❌ [FAQ] Could not extract list from response', name: 'FAQ');
    return [];
  }

  /// Helper method to extract single object from various API response formats
  Map<String, dynamic>? _extractObject(
    dynamic response, {
    String? preferredKey,
  }) {
    developer.log(
      '📦 [FAQ] _extractObject called with type: ${response.runtimeType}',
      name: 'FAQ',
    );

    if (response is Map<String, dynamic>) {
      developer.log(
        '📦 [FAQ] Response is Map with keys: ${response.keys}',
        name: 'FAQ',
      );

      if (preferredKey != null &&
          response.containsKey(preferredKey) &&
          response[preferredKey] is Map<String, dynamic>) {
        developer.log(
          '📦 [FAQ] Found object in preferred key "$preferredKey"',
          name: 'FAQ',
        );
        return response[preferredKey];
      }

      // Check common wrapper keys
      const wrapperKeys = ['faq', 'data', 'result', 'item'];
      for (final key in wrapperKeys) {
        if (response.containsKey(key) &&
            response[key] is Map<String, dynamic>) {
          developer.log(
            '📦 [FAQ] Found object in wrapper key "$key"',
            name: 'FAQ',
          );
          return response[key];
        }
      }

      return response;
    }

    developer.log(
      '⚠️ [FAQ] Response is not a Map: ${response.runtimeType}',
      name: 'FAQ',
    );
    return null;
  }

  @override
  Future<List<FaqModel>> getActiveFaqs() async {
    developer.log('🔍 [FAQ] Fetching active FAQs...', name: 'FAQ');

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/faq/active');
      developer.log('🌐 [FAQ] GET $url', name: 'FAQ');

      final response = await client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      developer.log(
        '📡 [FAQ] Active Response Status: ${response.statusCode}',
        name: 'FAQ',
      );
      developer.log(
        '📡 [FAQ] Active Response Body: ${response.body.substring(0, min(500, response.body.length))}...',
        name: 'FAQ',
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        developer.log(
          '📦 [FAQ] Active response type: ${decoded.runtimeType}',
          name: 'FAQ',
        );

        // Debug: Print structure
        if (decoded is Map) {
          developer.log(
            '📦 [FAQ] Active response keys: ${decoded.keys}',
            name: 'FAQ',
          );
          // Check if 'faqs' key exists
          if (decoded.containsKey('faqs')) {
            final faqsValue = decoded['faqs'];
            developer.log(
              '📦 [FAQ] "faqs" key type: ${faqsValue.runtimeType}',
              name: 'FAQ',
            );
            if (faqsValue is List) {
              developer.log(
                '📦 [FAQ] "faqs" list length: ${faqsValue.length}',
                name: 'FAQ',
              );
            }
          }
        }

        final jsonList = _extractList(decoded, preferredKey: 'faqs');
        developer.log(
          '✅ [FAQ] Found ${jsonList.length} active FAQs',
          name: 'FAQ',
        );

        if (jsonList.isEmpty) {
          developer.log('⚠️ [FAQ] No FAQs found in response', name: 'FAQ');
          return [];
        }

        final faqs = jsonList
            .map((json) {
              try {
                return FaqModel.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                developer.log('❌ [FAQ] Error parsing FAQ: $e', name: 'FAQ');
                developer.log('❌ [FAQ] Problematic JSON: $json', name: 'FAQ');
                return null;
              }
            })
            .where((faq) => faq != null)
            .cast<FaqModel>()
            .toList();

        developer.log(
          '✅ [FAQ] Successfully parsed ${faqs.length} FAQs',
          name: 'FAQ',
        );
        return faqs;
      } else {
        developer.log(
          '❌ [FAQ] Failed with status: ${response.statusCode}',
          name: 'FAQ',
        );
        throw ServerException('Failed to load FAQs: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      developer.log('❌ [FAQ] Error loading active FAQs: $e', name: 'FAQ');
      developer.log('📚 [FAQ] Stacktrace: $stacktrace', name: 'FAQ');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<List<FaqModel>> getAllFaqs() async {
    developer.log('🔍 [FAQ] Fetching all FAQs...', name: 'FAQ');

    try {
      final token = await _getToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/faq');
      developer.log('🌐 [FAQ] GET $url', name: 'FAQ');

      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        '📡 [FAQ] All Response Status: ${response.statusCode}',
        name: 'FAQ',
      );

      // Log first 500 chars of response
      final preview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      developer.log(
        '📡 [FAQ] All Response Body preview: $preview',
        name: 'FAQ',
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        developer.log(
          '📦 [FAQ] All response type: ${decoded.runtimeType}',
          name: 'FAQ',
        );

        // Debug: Print keys if it's a map
        if (decoded is Map) {
          developer.log(
            '📦 [FAQ] All response keys: ${decoded.keys}',
            name: 'FAQ',
          );

          // Check for common patterns
          if (decoded.containsKey('faqs')) {
            developer.log(
              '📦 [FAQ] "faqs" key found, type: ${decoded['faqs'].runtimeType}',
              name: 'FAQ',
            );
          }
          if (decoded.containsKey('data')) {
            developer.log(
              '📦 [FAQ] "data" key found, type: ${decoded['data'].runtimeType}',
              name: 'FAQ',
            );
          }
          if (decoded.containsKey('success')) {
            developer.log(
              '📦 [FAQ] "success" = ${decoded['success']}',
              name: 'FAQ',
            );
          }
        }

        final jsonList = _extractList(decoded, preferredKey: 'faqs');
        developer.log('✅ [FAQ] Found ${jsonList.length} FAQs', name: 'FAQ');

        if (jsonList.isEmpty) {
          developer.log('⚠️ [FAQ] No FAQs found in response', name: 'FAQ');
          return [];
        }

        final faqs = jsonList
            .map((json) {
              try {
                return FaqModel.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                developer.log('❌ [FAQ] Error parsing FAQ: $e', name: 'FAQ');
                developer.log('❌ [FAQ] Problematic JSON: $json', name: 'FAQ');
                return null;
              }
            })
            .where((faq) => faq != null)
            .cast<FaqModel>()
            .toList();

        developer.log(
          '✅ [FAQ] Successfully parsed ${faqs.length} FAQs',
          name: 'FAQ',
        );
        return faqs;
      } else if (response.statusCode == 401) {
        developer.log(
          '❌ [FAQ] Unauthorized - Token may be invalid',
          name: 'FAQ',
        );
        throw ServerException('Unauthorized - Please login again');
      } else {
        developer.log(
          '❌ [FAQ] Failed with status: ${response.statusCode}',
          name: 'FAQ',
        );
        throw ServerException('Failed to load FAQs: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      developer.log('❌ [FAQ] Error loading all FAQs: $e', name: 'FAQ');
      developer.log('📚 [FAQ] Stacktrace: $stacktrace', name: 'FAQ');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<List<FaqModel>> getFaqsByCategory(String category) async {
    developer.log('🔍 [FAQ] Fetching FAQs by category: $category', name: 'FAQ');

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/faq/category/$category');
      developer.log('🌐 [FAQ] GET $url', name: 'FAQ');

      final response = await client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      developer.log(
        '📡 [FAQ] Category Response Status: ${response.statusCode}',
        name: 'FAQ',
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final jsonList = _extractList(decoded, preferredKey: 'faqs');
        developer.log(
          '✅ [FAQ] Found ${jsonList.length} FAQs for category: $category',
          name: 'FAQ',
        );

        return jsonList
            .map((json) => FaqModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Failed to load FAQs by category: ${response.statusCode}',
        );
      }
    } catch (e) {
      developer.log('❌ [FAQ] Error loading FAQs by category: $e', name: 'FAQ');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<List<String>> getFaqCategories() async {
    developer.log('🔍 [FAQ] Fetching FAQ categories...', name: 'FAQ');

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/faq/categories');
      developer.log('🌐 [FAQ] GET $url', name: 'FAQ');

      final response = await client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      developer.log(
        '📡 [FAQ] Categories Response Status: ${response.statusCode}',
        name: 'FAQ',
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        developer.log(
          '📦 [FAQ] Categories response type: ${decoded.runtimeType}',
          name: 'FAQ',
        );

        if (decoded is List) {
          developer.log(
            '✅ [FAQ] Found ${decoded.length} categories (direct list)',
            name: 'FAQ',
          );
          return decoded.map((item) => item.toString()).toList();
        } else if (decoded is Map && decoded.containsKey('categories')) {
          final categories = decoded['categories'];
          if (categories is List) {
            developer.log(
              '✅ [FAQ] Found ${categories.length} categories (in "categories" key)',
              name: 'FAQ',
            );
            return categories.map((item) => item.toString()).toList();
          }
        } else if (decoded is Map && decoded.containsKey('data')) {
          final data = decoded['data'];
          if (data is List) {
            developer.log(
              '✅ [FAQ] Found ${data.length} categories (in "data" key)',
              name: 'FAQ',
            );
            return data.map((item) => item.toString()).toList();
          }
        }

        developer.log('⚠️ [FAQ] No categories found in response', name: 'FAQ');
        return [];
      } else {
        throw ServerException(
          'Failed to load FAQ categories: ${response.statusCode}',
        );
      }
    } catch (e) {
      developer.log('❌ [FAQ] Error loading categories: $e', name: 'FAQ');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<FaqModel> getFaqById(String id) async {
    developer.log('🔍 [FAQ] Fetching FAQ by ID: $id', name: 'FAQ');

    try {
      final token = await _getToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/faq/$id');
      developer.log('🌐 [FAQ] GET $url', name: 'FAQ');

      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        '📡 [FAQ] GetById Response Status: ${response.statusCode}',
        name: 'FAQ',
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = _extractObject(decoded, preferredKey: 'faq') ?? decoded;
        developer.log('✅ [FAQ] Successfully fetched FAQ: $id', name: 'FAQ');
        return FaqModel.fromJson(data);
      } else {
        throw ServerException('Failed to load FAQ: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ [FAQ] Error loading FAQ by ID: $e', name: 'FAQ');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<FaqModel> createFaq(Map<String, dynamic> faqData) async {
    developer.log('🔍 [FAQ] Creating new FAQ', name: 'FAQ');

    try {
      final token = await _getToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/faq');
      developer.log('🌐 [FAQ] POST $url', name: 'FAQ');
      developer.log('📝 [FAQ] Request body: $faqData', name: 'FAQ');

      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(faqData),
      );

      developer.log(
        '📡 [FAQ] Create Response Status: ${response.statusCode}',
        name: 'FAQ',
      );
      developer.log(
        '📡 [FAQ] Create Response Body: ${response.body}',
        name: 'FAQ',
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = _extractObject(decoded, preferredKey: 'faq') ?? decoded;
        developer.log('✅ [FAQ] Successfully created FAQ', name: 'FAQ');
        return FaqModel.fromJson(data);
      } else {
        throw ServerException(
          'Failed to create FAQ: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      developer.log('❌ [FAQ] Error creating FAQ: $e', name: 'FAQ');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<FaqModel> updateFaq(String id, Map<String, dynamic> faqData) async {
    developer.log('🔍 [FAQ] Updating FAQ: $id', name: 'FAQ');

    try {
      final token = await _getToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/faq/$id');
      developer.log('🌐 [FAQ] PUT $url', name: 'FAQ');
      developer.log('📝 [FAQ] Request body: $faqData', name: 'FAQ');

      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(faqData),
      );

      developer.log(
        '📡 [FAQ] Update Response Status: ${response.statusCode}',
        name: 'FAQ',
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = _extractObject(decoded, preferredKey: 'faq') ?? decoded;
        developer.log('✅ [FAQ] Successfully updated FAQ: $id', name: 'FAQ');
        return FaqModel.fromJson(data);
      } else {
        throw ServerException('Failed to update FAQ: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ [FAQ] Error updating FAQ: $e', name: 'FAQ');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<void> deleteFaq(String id) async {
    developer.log('🔍 [FAQ] Deleting FAQ: $id', name: 'FAQ');

    try {
      final token = await _getToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/faq/$id');
      developer.log('🌐 [FAQ] DELETE $url', name: 'FAQ');

      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        '📡 [FAQ] Delete Response Status: ${response.statusCode}',
        name: 'FAQ',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        developer.log('✅ [FAQ] Successfully deleted FAQ: $id', name: 'FAQ');
      } else {
        throw ServerException('Failed to delete FAQ: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ [FAQ] Error deleting FAQ: $e', name: 'FAQ');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<FaqModel> toggleFaqStatus(String id) async {
    developer.log('🔍 [FAQ] Toggling FAQ status: $id', name: 'FAQ');

    try {
      final token = await _getToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/faq/$id/toggle');
      developer.log('🌐 [FAQ] PUT $url', name: 'FAQ');

      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        '📡 [FAQ] Toggle Response Status: ${response.statusCode}',
        name: 'FAQ',
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = _extractObject(decoded, preferredKey: 'faq') ?? decoded;
        developer.log(
          '✅ [FAQ] Successfully toggled FAQ status: $id',
          name: 'FAQ',
        );
        return FaqModel.fromJson(data);
      } else {
        throw ServerException(
          'Failed to toggle FAQ status: ${response.statusCode}',
        );
      }
    } catch (e) {
      developer.log('❌ [FAQ] Error toggling FAQ status: $e', name: 'FAQ');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<void> reorderFaqs(List<String> faqIds) async {
    developer.log(
      '🔍 [FAQ] Reordering FAQs: ${faqIds.length} items',
      name: 'FAQ',
    );

    try {
      final token = await _getToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/faq/reorder');
      developer.log('🌐 [FAQ] PUT $url', name: 'FAQ');
      developer.log(
        '📝 [FAQ] Reorder body: ${json.encode({'faqIds': faqIds})}',
        name: 'FAQ',
      );

      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'faqIds': faqIds}),
      );

      developer.log(
        '📡 [FAQ] Reorder Response Status: ${response.statusCode}',
        name: 'FAQ',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        developer.log('✅ [FAQ] Successfully reordered FAQs', name: 'FAQ');
      } else {
        throw ServerException('Failed to reorder FAQs: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ [FAQ] Error reordering FAQs: $e', name: 'FAQ');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }
}
