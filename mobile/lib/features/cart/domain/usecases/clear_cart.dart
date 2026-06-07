import 'package:fpdart/fpdart.dart';

import '../repositories/cart_repository.dart';

class ClearCart {
  final CartRepository repository;

  ClearCart(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.clearCart();
  }
}
