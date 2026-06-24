import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_event.dart';
import '../constants/api_constants.dart';

class ApiClient {
  final http.Client client;

  ApiClient({required this.client});

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers ?? ApiConstants.headers,
    );

    if (response.statusCode == 401) {
      // Token expired - logout user
      await _logoutUser();
      throw UnauthorizedException('Session expired. Please login again.');
    }
    return response;
  }

  Future<http.Response> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers ?? ApiConstants.headers,
      body: body,
    );

    if (response.statusCode == 401) {
      await _logoutUser();
      throw UnauthorizedException('Session expired. Please login again.');
    }
    return response;
  }

  Future<http.Response> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final response = await client.put(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers ?? ApiConstants.headers,
      body: body,
    );

    if (response.statusCode == 401) {
      await _logoutUser();
      throw UnauthorizedException('Session expired. Please login again.');
    }
    return response;
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final response = await client.delete(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers ?? ApiConstants.headers,
    );

    if (response.statusCode == 401) {
      await _logoutUser();
      throw UnauthorizedException('Session expired. Please login again.');
    }
    return response;
  }

  Future<void> _logoutUser() async {
    final authBloc = GetIt.instance<AuthBloc>();
    authBloc.add(LogoutEvent());
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}
