import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Category>> getCategories() async {
    try {
      final categories = await remoteDataSource.getCategories();
      return categories;
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  @override
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      final products = await remoteDataSource.getFeaturedProducts(limit: limit);
      return products;
    } catch (e) {
      throw Exception('Failed to get featured products: $e');
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final products = await remoteDataSource.getProductsByCategory(categoryId);
      return products;
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  @override
  Future<List<Product>> searchProducts({
    String? query,
    double? minPrice,
    double? maxPrice,
    String? categoryId,
    String? sortBy,
  }) async {
    try {
      final products = await remoteDataSource.searchProducts(
        query: query,
        minPrice: minPrice,
        maxPrice: maxPrice,
        categoryId: categoryId,
        sortBy: sortBy,
      );
      return products;
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    try {
      final product = await remoteDataSource.getProductById(id);
      return product;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  @override
  Future<Product> getProductBySlug(String slug) async {
    try {
      final product = await remoteDataSource.getProductBySlug(slug);
      return product;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }
}
