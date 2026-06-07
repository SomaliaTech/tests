import '../../domain/entities/cart_item.dart';

class CartLocalDataSource {
  List<CartItem> _items = [];

  CartLocalDataSource() {
    _items = _getMockData();
  }

  List<CartItem> get items => List.unmodifiable(_items);

  Future<List<CartItem>> getCartItems() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _items;
  }

  Future<void> updateQuantity(String id, int quantity) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: quantity);
    }
  }

  Future<void> removeItem(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _items.removeWhere((item) => item.id == id);
  }

  Future<void> clearCart() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _items.clear();
  }

  List<CartItem> _getMockData() {
    return [
      const CartItem(
        id: '1',
        name: 'MIISAANKA BODY+ FAT',
        price: 15.00,
        quantity: 1,
        imageUrl:
            'https://images.unsplash.com/photo-1576243345690-8e4b879f2c6e?w=200&h=200&fit=crop',
        inStock: true,
        maxStock: 10,
      ),
      const CartItem(
        id: '2',
        name: 'ABDOMINAL WHEEL ROLLER',
        price: 16.00,
        quantity: 2,
        imageUrl:
            'https://images.unsplash.com/photo-1598289431512-b97b0917affc?w=200&h=200&fit=crop',
        inStock: true,
        maxStock: 5,
      ),
      const CartItem(
        id: '3',
        name: 'Smart Watch Pro',
        price: 89.00,
        quantity: 1,
        imageUrl:
            'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=200&h=200&fit=crop',
        inStock: false,
        maxStock: 0,
      ),
    ];
  }
}
