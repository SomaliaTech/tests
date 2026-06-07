import 'package:fpdart/fpdart.dart';

import '../repositories/cart_repository.dart';

class UpdateQuantity {
  final CartRepository repository;

  UpdateQuantity(this.repository);

  Future<Either<Failure, void>> call(String id, int quantity) async {
    if (quantity < 1) {
      return Left(Failure('Quantity must be at least 1'));
    }
    return await repository.updateQuantity(id, quantity);
  }
}
