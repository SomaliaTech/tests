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

class GetFeaturedProductsEvent extends ProductEvent {}

class SearchProductsEvent extends ProductEvent {
  final String? query;
  const SearchProductsEvent(this.query);

  @override
  List<Object?> get props => [query];
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
