import '../../../../core/utils/typedefs.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductBySlug {
  final ProductRepository repository;

  const GetProductBySlug(this.repository);

  ResultFuture<Product> call(String slug) async {
    return await repository.getProductBySlug(slug);
  }
}
