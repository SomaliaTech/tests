import '../../../../core/utils/typedefs.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsByCategory {
  final ProductRepository repository;

  GetProductsByCategory(this.repository);

  ResultFuture<List<Product>> call(String categoryId) async {
    return await repository.getProductsByCategory(categoryId);
  }
}
