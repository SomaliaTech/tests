import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> sendOtp(
    String phoneNumber,
  ); // Changed to return Map
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
  ); // Changed to return Map
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
    String? email,
    String? profileImageUrl,
  ) async {
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
      } else if (response.statusCode == 401) {
        // 🚨 Throw specific exception for 401
        throw UnauthorizedException('Token expired or invalid');
      } else {
        throw ServerException('Failed to get user: ${response.statusCode}');
      }
    } on UnauthorizedException {
      rethrow; // Pass it up to the repository
    } catch (e) {
      // This catches SocketException (no internet)
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
