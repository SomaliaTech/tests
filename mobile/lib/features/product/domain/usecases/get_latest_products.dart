import '../../../../core/utils/typedefs.dart'; // ✅ Use ResultFuture instead of fpdart Either
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetLatestProducts {
  final ProductRepository repository;

  const GetLatestProducts(
    this.repository,
  ); // ✅ Added const to match GetFeaturedProducts

  ResultFuture<List<Product>> call({int limit = 10}) async {
    // ✅ Changed return type
    return await repository.getLatestProducts(limit: limit);
  }
}
