import '../../../../core/utils/typedefs.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductById {
  final ProductRepository repository;

  const GetProductById(this.repository);

  ResultFuture<Product> call(String id) async {
    return await repository.getProductById(id);
  }
}
