import '../../../../core/utils/typedefs.dart';
import '../entities/category.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  ResultFuture<List<Category>> getCategories();
  ResultFuture<List<Product>> getFeaturedProducts({int limit});
  ResultFuture<List<Product>> getProductsByCategory(String categoryId);
  ResultFuture<List<Category>> getSubcategories(String parentId); // Add this
  ResultFuture<List<Product>> searchProducts({
    String? query,
    double? minPrice,
    double? maxPrice,
    String? categoryId,
    String? sortBy,
  });
  ResultFuture<Product> getProductById(String id);
  ResultFuture<Product> getProductBySlug(String slug);
}
