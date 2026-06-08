import '../../../../core/utils/typedefs.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetFeaturedProducts {
  final ProductRepository repository;

  const GetFeaturedProducts(this.repository);

  ResultFuture<List<Product>> call({int limit = 10}) async {
    return await repository.getFeaturedProducts(limit: limit);
  }
}
