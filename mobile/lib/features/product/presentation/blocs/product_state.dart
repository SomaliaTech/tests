import 'package:equatable/equatable.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

// ==========================================
// 📂 Category Loading States
// ==========================================
class CategoriesLoading extends ProductState {}

class CategoriesLoaded extends ProductState {
  final List<Category> categories;
  const CategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class CategoriesError extends ProductState {
  final String message;
  const CategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==========================================
// 📂 Subcategory States
// ==========================================
class SubcategoriesLoading extends ProductState {}

class SubcategoriesLoaded extends ProductState {
  final List<Category> subcategories;
  const SubcategoriesLoaded(this.subcategories);

  @override
  List<Object?> get props => [subcategories];
}

class SubcategoriesError extends ProductState {
  final String message;
  const SubcategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==========================================
// 🏷️ Featured Products Loading States
// ==========================================
class FeaturedProductsLoading extends ProductState {}

class FeaturedProductsLoaded extends ProductState {
  final List<Product> products;
  const FeaturedProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class FeaturedProductsError extends ProductState {
  final String message;
  const FeaturedProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==========================================
// 📦 Single Product States
// ==========================================
class ProductDetailLoading extends ProductState {}

class ProductDetailLoaded extends ProductState {
  final Product product;
  const ProductDetailLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductDetailError extends ProductState {
  final String message;
  const ProductDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// Generic fallback or for other dynamic routes if needed
class ProductLoading extends ProductState {}

class ProductsLoaded extends ProductState {
  final List<Product> products;
  const ProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
