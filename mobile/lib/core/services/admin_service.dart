import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:get_it/get_it.dart';

class AdminService {
  static final StorageService _storageService =
      GetIt.instance<StorageService>();

  static Future<List<AdminUser>> getAdmins() async {
    try {
      final token = await _storageService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Filter users where isAdmin is true
        final adminUsers = data
            .where(
              (user) => user['isAdmin'] == true || user['is_admin'] == true,
            )
            .map((user) => AdminUser.fromJson(user))
            .toList();
        return adminUsers;
      } else {
        throw Exception('Failed to fetch admins: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching admins: $e');
      return [];
    }
  }

  static Future<AdminUser?> getFirstAdmin() async {
    final admins = await getAdmins();
    if (admins.isNotEmpty) {
      return admins.first;
    }
    return null;
  }
}

class AdminUser {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? email;
  final String? profileImage;
  final bool isAdmin;

  AdminUser({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.email,
    this.profileImage,
    this.isAdmin = true,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
      profileImage: json['profileImage'] ?? json['profile_image'] as String?,
      isAdmin: json['isAdmin'] ?? json['is_admin'] ?? false,
    );
  }

  String get displayName => name ?? 'Support Team';
}
