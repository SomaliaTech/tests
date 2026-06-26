import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:get_it/get_it.dart';

class AdminService {
  static final StorageService _storageService =
      GetIt.instance<StorageService>();

  // ✅ Get available admins from the chat endpoint
  static Future<List<AdminUser>> getAvailableAdmins() async {
    try {
      final token = await _storageService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chat/admins'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((json) => AdminUser.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch admins: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching admins: $e');
      return [];
    }
  }

  // ✅ Get first available admin (preferably online)
  static Future<AdminUser?> getFirstAdmin() async {
    try {
      final admins = await getAvailableAdmins();

      if (admins.isEmpty) {
        return null;
      }

      // Try to find an online admin first
      for (final admin in admins) {
        if (admin.isOnline) {
          return admin;
        }
      }

      // Fallback to first admin
      return admins.first;
    } catch (e) {
      print('❌ Error getting first admin: $e');
      return null;
    }
  }
}

class AdminUser {
  final String id;
  final String? phoneNumber;
  final String? name;
  final String? email;
  final String? profileImage;
  final bool isAdmin;
  final bool isOnline;

  AdminUser({
    required this.id,
    this.phoneNumber,
    this.name,
    this.email,
    this.profileImage,
    this.isAdmin = true,
    this.isOnline = false,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String? ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
      profileImage: json['profileImage'] ?? json['profile_image'] as String?,
      isAdmin: json['isAdmin'] ?? json['is_admin'] ?? true,
      isOnline: json['isOnline'] ?? json['is_online'] ?? false, // 🚨 ADDED
    );
  }

  String get displayName => name ?? 'Support Team';
}
