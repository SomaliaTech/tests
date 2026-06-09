import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';

abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> getProfile(String token);
  Future<Map<String, dynamic>> updateProfile(
    String token,
    String name,
    String? email,
    String? marketId,
  );
  Future<Map<String, dynamic>> uploadProfileImage(
    String token,
    String base64Image,
  );
  Future<void> deleteAccount(String token);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final http.Client client;

  ProfileRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ServerException('Failed to get profile: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> updateProfile(
    String token,
    String name,
    String? email,
    String? marketId,
  ) async {
    try {
      final response = await client.patch(
        Uri.parse('${ApiConstants.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          if (email != null) 'email': email,
          if (marketId != null) 'marketId': marketId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ServerException(
          'Failed to update profile: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> uploadProfileImage(
    String token,
    String base64Image,
  ) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/upload-profile-image'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'imageUrl': base64Image}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw ServerException('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<void> deleteAccount(String token) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}/auth/account'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          'Failed to delete account: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }
}
