// lib/features/product/presentation/blocs/product_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

// Loading states
class ProductLoading extends ProductState {}

class ProductDetailLoading extends ProductState {}

class CategoriesLoading extends ProductState {}

class FeaturedProductsLoading extends ProductState {}

class SubcategoriesLoading extends ProductState {}

// Error states
class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProductDetailError extends ProductState {
  final String message;
  const ProductDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class CategoriesError extends ProductState {
  final String message;
  const CategoriesError(this.message);
  @override
  List<Object?> get props => [message];
}

class FeaturedProductsError extends ProductState {
  final String message;
  const FeaturedProductsError(this.message);
  @override
  List<Object?> get props => [message];
}

class SubcategoriesError extends ProductState {
  final String message;
  const SubcategoriesError(this.message);
  @override
  List<Object?> get props => [message];
}

// Loaded states
class CategoriesLoaded extends ProductState {
  final List<Category> categories;
  const CategoriesLoaded(this.categories);
  @override
  List<Object?> get props => [categories];
}

class SubcategoriesLoaded extends ProductState {
  final List<Category> subcategories;
  const SubcategoriesLoaded(this.subcategories);
  @override
  List<Object?> get props => [subcategories];
}

class FeaturedProductsLoaded extends ProductState {
  final List<Product> products;
  const FeaturedProductsLoaded(this.products);
  @override
  List<Object?> get props => [products];
}

class ProductsLoaded extends ProductState {
  final List<Product> products;
  const ProductsLoaded(this.products);
  @override
  List<Object?> get props => [products];
}

class ProductDetailLoaded extends ProductState {
  final Product product;
  const ProductDetailLoaded(this.product);
  @override
  List<Object?> get props => [product];
}

class LatestProductsLoading extends ProductState {}

class LatestProductsLoaded extends ProductState {
  final List<Product> products;
  const LatestProductsLoaded(this.products);

  @override
  List<Object?> get props => [products]; // ✅ Added
}

class LatestProductsError extends ProductState {
  final String message;
  const LatestProductsError(this.message);

  @override
  List<Object?> get props => [message]; // ✅ Added
}
