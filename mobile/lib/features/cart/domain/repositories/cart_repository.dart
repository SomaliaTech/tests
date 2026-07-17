import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/cart_item.dart';

abstract class CartRepository {
  ResultFuture<List<CartItem>> getCartItems();
  ResultFuture<void> addToCart(CartItem item); // ✅ ADD THIS
  ResultFuture<void> updateQuantity(String itemId, int quantity);
  ResultFuture<void> removeItem(String itemId);
  ResultFuture<void> clearCart();
}
