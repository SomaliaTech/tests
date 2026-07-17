import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/cart_item.dart';
import '../models/cart_item_model.dart';

abstract class CartLocalDataSource {
  Future<List<CartItem>> getCachedCartItems();
  Future<void> cacheCartItems(List<CartItem> items);
  Future<void> addToCache(CartItem item);
  Future<void> updateCacheItem(String productVariantId, int quantity);
  Future<void> removeFromCart(String productVariantId);
  Future<void> clearCache();
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  static const String _cartCacheKey = 'cached_cart_items';
  final SharedPreferences sharedPreferences;

  CartLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<CartItem>> getCachedCartItems() async {
    final jsonString = sharedPreferences.getString(_cartCacheKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      // 🚨 FIXED: Added the missing closing parenthesis
      return jsonList.map((json) => CartItemModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheCartItems(List<CartItem> items) async {
    final jsonList = items.map((item) => CartItemModel.toJson(item)).toList();
    await sharedPreferences.setString(_cartCacheKey, json.encode(jsonList));
  }

  @override
  Future<void> addToCache(CartItem item) async {
    final items = await getCachedCartItems();

    final existingIndex = items.indexWhere((i) {
      // Same matching logic as bloc
      if (i.productVariantId.isNotEmpty && item.productVariantId.isNotEmpty) {
        return i.productVariantId == item.productVariantId;
      }
      return i.productId == item.productId;
    });

    if (existingIndex != -1) {
      final existingItem = items[existingIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + item.quantity,
      );
      final updatedItems = List<CartItem>.from(items);
      updatedItems[existingIndex] = updatedItem;
      await cacheCartItems(updatedItems);
    } else {
      await cacheCartItems([...items, item]);
    }
  }

  @override
  Future<void> updateCacheItem(String productVariantId, int quantity) async {
    final items = await getCachedCartItems();
    // 🚨 FIXED: Match by productVariantId
    final index = items.indexWhere(
      (item) => item.productVariantId == productVariantId,
    );

    if (index != -1) {
      final old = items[index];
      final updatedItem = CartItem(
        id: old.id,
        productId: old.productId,
        productVariantId: old.productVariantId,
        name: old.name,
        imageUrl: old.imageUrl,
        price: old.price,
        quantity: quantity,
        maxStock: old.maxStock,
        inStock: old.inStock,
        color: old.color,
        size: old.size,
      );
      final updatedItems = List<CartItem>.from(items);
      updatedItems[index] = updatedItem;
      await cacheCartItems(updatedItems);
    }
  }

  @override
  Future<void> removeFromCart(String productVariantId) async {
    final items = await getCachedCartItems();
    // 🚨 FIXED: Filter by productVariantId
    final updatedItems = items
        .where((item) => item.productVariantId != productVariantId)
        .toList();
    await cacheCartItems(updatedItems);
  }

  @override
  Future<void> clearCache() async {
    // 🚨 FIXED: Corrected variable name
    await sharedPreferences.remove(_cartCacheKey);
  }
}
