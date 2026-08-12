// lib/features/auth/data/datasources/auth_remote_data_source.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> sendOtp(String phoneNumber);
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otpCode);

  // ✅ Add phoneNumber parameter
  Future<Map<String, dynamic>> completeProfile(
    String token,
    String name,
    String marketId,
    String? profileImageUrl,
    String? phoneNumber, // ✅ Add this
  );

  Future<Map<String, dynamic>> getCurrentUser(String token);
  Future<Map<String, dynamic>> uploadProfileImage(
    String token,
    String base64Image,
  );
  Future<Map<String, dynamic>> googleSignIn(
    String idToken,
    String email,
    String name,
    String? photoUrl,
  );
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> googleSignIn(
    String idToken,
    String email,
    String name,
    String? photoUrl,
  ) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken': idToken,
          'email': email,
          'name': name,
          'photoUrl': photoUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw ServerException(error['message'] ?? 'Google sign in failed');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

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
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otpCode,
  ) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phoneNumber': phoneNumber, 'otpCode': otpCode}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw ServerException('Invalid OTP or expired');
    }
  }

  @override
  Future<Map<String, dynamic>> completeProfile(
    String token,
    String name,
    String marketId,
    String? profileImageUrl,
    String? phoneNumber,
  ) async {
    final Map<String, dynamic> body = {
      'name': name,
      'marketId': marketId,
      if (profileImageUrl != null) 'profileImage': profileImageUrl,
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phoneNumber': phoneNumber,
    };

    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/complete-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        // ✅ SAFELY parse NestJS error responses
        String errorMessage = 'Failed to complete profile';

        try {
          final errorBody = json.decode(response.body);

          // NestJS BadRequestException returns: { "message": "..." }
          if (errorBody['message'] is String) {
            errorMessage = errorBody['message'];
          }
          // NestJS class-validator returns: { "message": ["...", "..."] }
          else if (errorBody['message'] is List &&
              errorBody['message'].isNotEmpty) {
            errorMessage = errorBody['message'][0];
          }
        } catch (_) {
          // If JSON parsing fails (e.g., raw HTML 500 page), keep default message
        }

        throw ServerException(errorMessage);
      }
    } on ServerException {
      rethrow; // ✅ Pass the clean message up to the repository unchanged
    } catch (e) {
      // Only actual network/socket errors should be labeled as network errors
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
        print("user ${response.body}");
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token expired or invalid');
      } else {
        throw ServerException('Failed to get user: ${response.statusCode}');
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> uploadProfileImage(
    String token,
    String base64Image,
  ) async {
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
      throw ServerException('Failed to upload image');
    }
  }
}
