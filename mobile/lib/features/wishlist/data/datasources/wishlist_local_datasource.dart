import 'dart:convert';
import 'package:mobile/features/wishlist/data/model/wishlist_item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class WishlistLocalDataSource {
  Future<List<WishlistItemModel>> getWishlistItems();
  Future<void> saveWishlistItems(List<WishlistItemModel> items);
  Future<void> addItem(WishlistItemModel item);
  Future<void> removeItem(String itemId);
  Future<void> clearItems();
  Future<bool> isInWishlist(String itemId);
}

class WishlistLocalDataSourceImpl implements WishlistLocalDataSource {
  static const String _wishlistKey = 'wishlist_items';
  final SharedPreferences sharedPreferences;

  WishlistLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<WishlistItemModel>> getWishlistItems() async {
    final jsonString = sharedPreferences.getString(_wishlistKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => WishlistItemModel.fromJson(json)).toList();
  }

  @override
  Future<void> saveWishlistItems(List<WishlistItemModel> items) async {
    final jsonList = items.map((item) => item.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await sharedPreferences.setString(_wishlistKey, jsonString);
  }

  @override
  Future<void> addItem(WishlistItemModel item) async {
    final items = await getWishlistItems();
    final updatedItems = [...items, item];
    await saveWishlistItems(updatedItems);
  }

  @override
  Future<void> removeItem(String itemId) async {
    final items = await getWishlistItems();
    final updatedItems = items.where((item) => item.id != itemId).toList();
    await saveWishlistItems(updatedItems);
  }

  @override
  Future<void> clearItems() async {
    await sharedPreferences.remove(_wishlistKey);
  }

  @override
  Future<bool> isInWishlist(String itemId) async {
    final items = await getWishlistItems();
    return items.any((item) => item.id == itemId);
  }
}
