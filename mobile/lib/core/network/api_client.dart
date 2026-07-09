import 'dart:convert';
import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/network/session_handler.dart';
import 'package:mobile/core/services/server_status_service.dart'; // ✅ ADD THIS
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_event.dart';

class ApiClient {
  final http.Client client;
  final StorageService storageService;

  ApiClient({required this.client, required this.storageService});

  // ==========================================
  // GET
  // ==========================================
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final builtHeaders = await _buildHeaders(headers, requiresAuth);
    return _handleRequest(
      () => client.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: builtHeaders,
      ),
    );
  }

  // ==========================================
  // POST
  // ==========================================
  Future<http.Response> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final builtHeaders = await _buildHeaders(headers, requiresAuth);
    return _handleRequest(
      () => client.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: builtHeaders,
        body: body is String ? body : json.encode(body),
      ),
    );
  }

  // ==========================================
  // PUT
  // ==========================================
  Future<http.Response> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final builtHeaders = await _buildHeaders(headers, requiresAuth);
    return _handleRequest(
      () => client.put(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: builtHeaders,
        body: body is String ? body : json.encode(body),
      ),
    );
  }

  // ==========================================
  // DELETE
  // ==========================================
  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final builtHeaders = await _buildHeaders(headers, requiresAuth);
    return _handleRequest(
      () => client.delete(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: builtHeaders,
      ),
    );
  }

  // ==========================================
  // PRIVATE METHODS
  // ==========================================

  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? additionalHeaders,
    bool requiresAuth,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };

    if (requiresAuth) {
      final token = await storageService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ✅ SINGLE _handleRequest method
  Future<http.Response> _handleRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request();

      // ✅ Server is up!
      ServerStatusService().markServerUp();

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleUnauthorized();
        throw UnauthorizedException(
          response.statusCode == 401
              ? 'Session expired. Please login again.'
              : 'Access denied. You do not have permission.',
        );
      }

      return response;
    } on SocketException {
      // ✅ Server is down - no internet or connection refused
      ServerStatusService().markServerDown();
      rethrow;
    } catch (e) {
      // ✅ Check if it's a connection refused error
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection failed') ||
          e.toString().contains('Network is unreachable')) {
        ServerStatusService().markServerDown();
      }
      rethrow;
    }
  }

  Future<void> _handleUnauthorized() async {
    await storageService.clearAuthData();

    try {
      final authBloc = GetIt.instance<AuthBloc>();
      authBloc.add(LogoutEvent());
    } catch (e) {
      // debugPrint('❌ Failed to dispatch logout: $e');
    }

    SessionHandler.navigateToLogin();
  }
}
