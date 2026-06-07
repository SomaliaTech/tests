import 'package:fpdart/fpdart.dart';

import '../entities/cart_item.dart';

abstract class CartRepository {
  Future<Either<Failure, List<CartItem>>> getCartItems();
  Future<Either<Failure, void>> updateQuantity(String id, int quantity);
  Future<Either<Failure, void>> removeItem(String id);
  Future<Either<Failure, void>> clearCart();
}

class Failure {
  final String message;
  const Failure(this.message);
}
