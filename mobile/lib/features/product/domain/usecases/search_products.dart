import '../../../../core/utils/typedefs.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class SearchProducts {
  final ProductRepository repository;

  SearchProducts(this.repository);

  ResultFuture<List<Product>> call({
    String? query,
    double? minPrice,
    double? maxPrice,
    String? categoryId,
    String? sortBy,
  }) async {
    return await repository.searchProducts(
      query: query,
      minPrice: minPrice,
      maxPrice: maxPrice,
      categoryId: categoryId,
      sortBy: sortBy,
    );
  }
}
