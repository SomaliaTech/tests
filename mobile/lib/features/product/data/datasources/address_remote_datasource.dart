import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/address.dart';

abstract class AddressRemoteDataSource {
  Future<List<Address>> getAddresses(String token);
  Future<Address> addAddress(String token, Address address);
  Future<Address> setDefaultAddress(String token, String addressId);
  Future<void> deleteAddress(String token, String addressId);
}

class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  final http.Client client;

  AddressRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Address>> getAddresses(String token) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/orders/addresses'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Address.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load addresses');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<Address> addAddress(String token, Address address) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/orders/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(address.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Address.fromJson(json.decode(response.body));
      } else {
        throw ServerException('Failed to add address');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<Address> setDefaultAddress(String token, String addressId) async {
    try {
      final response = await client.put(
        Uri.parse(
          '${ApiConstants.baseUrl}/orders/addresses/$addressId/default',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return Address.fromJson(json.decode(response.body));
      } else {
        throw ServerException('Failed to set default address');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<void> deleteAddress(String token, String addressId) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}/orders/addresses/$addressId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Failed to delete address');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }
}
