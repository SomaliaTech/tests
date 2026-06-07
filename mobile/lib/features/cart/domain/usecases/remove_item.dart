import 'package:fpdart/fpdart.dart';

import '../repositories/cart_repository.dart';

class RemoveItem {
  final CartRepository repository;

  RemoveItem(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.removeItem(id);
  }
}
