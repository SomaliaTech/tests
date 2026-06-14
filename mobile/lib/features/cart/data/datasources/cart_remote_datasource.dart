import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/cart_item.dart';
import '../models/cart_item_model.dart';
// This was missing

abstract class CartRemoteDataSource {
  Future<List<CartItem>> getCartItems(String token);
  Future<CartItem> addToCart(
    String token,
    String productVariantId,
    int quantity,
  );
  Future<CartItem> updateCartItem(String token, String itemId, int quantity);
  Future<void> removeCartItem(String token, String itemId);
  Future<void> clearCart(String token);
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final http.Client client;

  CartRemoteDataSourceImpl({required this.client});

  @override
  Future<List<CartItem>> getCartItems(String token) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/orders/cart'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> itemsList;

        if (data is Map<String, dynamic> && data.containsKey('items')) {
          itemsList = data['items'] as List<dynamic>;
        } else if (data is List<dynamic>) {
          itemsList = data;
        } else {
          itemsList = [];
        }

        return itemsList.map((json) => CartItemModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load cart items');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<CartItem> addToCart(
    String token,
    String productVariantId,
    int quantity,
  ) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/orders/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productVariantId': productVariantId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CartItemModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException('Failed to add item to cart');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<CartItem> updateCartItem(
    String token,
    String itemId,
    int quantity,
  ) async {
    try {
      print('🔄 Updating cart item:');
      print('   Item ID: $itemId');
      print('   Quantity: $quantity');
      print('   URL: ${ApiConstants.baseUrl}/orders/cart/$itemId');

      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}/orders/cart/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'quantity': quantity}),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return CartItemModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException(
          'Failed to update cart item: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<void> removeCartItem(String token, String itemId) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}/orders/cart/$itemId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Failed to remove cart item');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<void> clearCart(String token) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}/orders/cart'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Failed to clear cart');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }
}
