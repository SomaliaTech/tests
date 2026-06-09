// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> sendOtp(String phoneNumber);
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otpCode);
  Future<Map<String, dynamic>> completeProfile(
    String token,
    String name,
    String? email,
    String? profileImageUrl,
  );
  Future<Map<String, dynamic>> getCurrentUser(String token);
  Future<Map<String, dynamic>> uploadProfileImage(
    String token,
    String base64Image,
  );
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phoneNumber}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ServerException('Failed to send OTP: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  @override
  Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otpCode,
  ) async {
    try {
      // DEBUG: Print exactly what is being sent
      print('📤 Sending to backend:');
      print('   phoneNumber: $phoneNumber');
      print('   otpCode: $otpCode');

      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          // ️ THESE KEYS MUST MATCH YOUR NESTJS DTO EXACTLY
          'phoneNumber': phoneNumber,
          'otpCode': otpCode,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        String errorMessage = 'Verification failed';
        if (responseData['message'] is List) {
          errorMessage = (responseData['message'] as List).join(', ');
        } else if (responseData['message'] is String) {
          errorMessage = responseData['message'];
        }
        throw ServerException(errorMessage);
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> completeProfile(
    String token,
    String name,
    String? email,
    String? profileImageUrl,
  ) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/complete-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          if (email != null) 'email': email,
          if (profileImageUrl != null) 'profileImage': profileImageUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw ServerException('Failed to complete profile');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ServerException('Failed to get user');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
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
        Uri.parse('${ApiConstants.baseUrl}/auth/upload-profile-image-url'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'imageUrl': base64Image}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw ServerException('Failed to upload image');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }
}
