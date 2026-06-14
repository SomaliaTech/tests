import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/cart_item.dart';
import '../models/cart_item_model.dart';

abstract class CartLocalDataSource {
  Future<List<CartItem>> getCachedCartItems();
  Future<void> cacheCartItems(List<CartItem> items);
  Future<void> addToCache(CartItem item);
  Future<void> updateCacheItem(String itemId, int quantity);
  Future<void> removeFromCache(String itemId);
  Future<void> clearCache();
  Future<int> getCachedItemCount();
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  static const String _cartCacheKey = 'cached_cart_items';
  final SharedPreferences sharedPreferences;

  CartLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<CartItem>> getCachedCartItems() async {
    final jsonString = sharedPreferences.getString(_cartCacheKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => CartItemModel.fromJson(json)).toList();
  }

  @override
  Future<void> cacheCartItems(List<CartItem> items) async {
    final jsonList = items.map((item) => CartItemModel.toJson(item)).toList();
    final jsonString = json.encode(jsonList);
    await sharedPreferences.setString(_cartCacheKey, jsonString);
  }

  @override
  Future<void> addToCache(CartItem item) async {
    final items = await getCachedCartItems();
    final existingIndex = items.indexWhere((i) => i.id == item.id);

    if (existingIndex != -1) {
      // Update existing item
      final updatedItems = List<CartItem>.from(items);
      updatedItems[existingIndex] = item;
      await cacheCartItems(updatedItems);
    } else {
      // Add new item
      await cacheCartItems([...items, item]);
    }
  }

  @override
  Future<void> updateCacheItem(String itemId, int quantity) async {
    final items = await getCachedCartItems();
    final index = items.indexWhere((item) => item.id == itemId);

    if (index != -1) {
      final updatedItem = CartItem(
        id: items[index].id,
        productId: items[index].productId,
        productVariantId: items[index].productVariantId,
        name: items[index].name,
        imageUrl: items[index].imageUrl,
        price: items[index].price,
        quantity: quantity,
        maxStock: items[index].maxStock,
        inStock: items[index].inStock,
        color: items[index].color,
        size: items[index].size,
      );

      final updatedItems = List<CartItem>.from(items);
      updatedItems[index] = updatedItem;
      await cacheCartItems(updatedItems);
    }
  }

  @override
  Future<void> removeFromCache(String itemId) async {
    final items = await getCachedCartItems();
    final updatedItems = items.where((item) => item.id != itemId).toList();
    await cacheCartItems(updatedItems);
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(_cartCacheKey);
  }

  @override
  Future<int> getCachedItemCount() async {
    final items = await getCachedCartItems();
    // Use a simple for loop instead of fold
    int totalCount = 0;
    for (var item in items) {
      totalCount += item.quantity;
    }
    return totalCount;
  }
}
