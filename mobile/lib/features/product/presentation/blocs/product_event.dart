// lib/features/product/presentation/blocs/product_event.dart
import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class GetCategoriesEvent extends ProductEvent {}

class GetSubcategoriesEvent extends ProductEvent {
  final String parentId;
  const GetSubcategoriesEvent(this.parentId);

  @override
  List<Object?> get props => [parentId];
}

class ResetProductStateEvent extends ProductEvent {}

class GetProductsByCategoryEvent extends ProductEvent {
  final String categoryId;
  const GetProductsByCategoryEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class GetProductByIdEvent extends ProductEvent {
  final String productId;
  const GetProductByIdEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

// ✅ REMOVED abstract keyword
class SearchProductsEvent extends ProductEvent {
  final String? query;
  final double? minPrice;
  final double? maxPrice;
  final String? categoryId;
  final String? sortBy;

  const SearchProductsEvent({
    this.query,
    this.minPrice,
    this.maxPrice,
    this.categoryId,
    this.sortBy,
  });

  @override
  List<Object?> get props => [query, minPrice, maxPrice, categoryId, sortBy];
}

class GetLatestProductsEvent extends ProductEvent {
  final int? limit;
  final bool forceRefresh;
  const GetLatestProductsEvent({this.limit, this.forceRefresh = false});
}

// ✅ REMOVED abstract keyword
// In ProductBloc, add a force refresh option
class GetFeaturedProductsEvent extends ProductEvent {
  final int? limit;
  final bool forceRefresh; // ✅ Add this

  const GetFeaturedProductsEvent({this.limit, this.forceRefresh = false});

  @override
  List<Object?> get props => [limit, forceRefresh];
}
