import 'package:flutter/material.dart';
import 'package:mobile/features/wishlist/presentation/model/wishlist_item_model.dart';

class WishlistProvider extends ChangeNotifier {
  List<WishlistItem> _items = [];

  List<WishlistItem> get items => _items;

  bool get isWishlistEmpty => _items.isEmpty;

  WishlistProvider() {
    // Load mock data (in real app, this would come from API/local storage)
    _items = List.from(mockWishlistItems);
  }

  void addToWishlist(WishlistItem item) {
    if (!_items.any((existing) => existing.id == item.id)) {
      _items.add(item);
      notifyListeners();
    }
  }

  void removeFromWishlist(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void clearWishlist() {
    _items.clear();
    notifyListeners();
  }

  bool isInWishlist(String itemId) {
    return _items.any((item) => item.id == itemId);
  }
}
