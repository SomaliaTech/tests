import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class CategoriesLoaded extends ProductState {
  final List<Category> categories;
  CategoriesLoaded(this.categories);
}

class ProductsLoaded extends ProductState {
  final List<Product> products;
  ProductsLoaded(this.products);
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}
