import '../../../../core/utils/typedefs.dart';
import '../entities/cart_item.dart';

abstract class CartRepository {
  ResultFuture<List<CartItem>> getCartItems();
  ResultFuture<CartItem> addToCart(String productVariantId, int quantity);
  ResultFuture<CartItem> updateQuantity(String itemId, int quantity);
  ResultFuture<void> removeItem(String itemId);
  ResultFuture<void> clearCart();
}
