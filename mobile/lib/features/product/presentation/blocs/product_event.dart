abstract class ProductEvent {}

class GetCategoriesEvent extends ProductEvent {}

class GetFeaturedProductsEvent extends ProductEvent {}

class GetProductsByCategoryEvent extends ProductEvent {
  final String categoryId;
  GetProductsByCategoryEvent(this.categoryId);
}

class SearchProductsEvent extends ProductEvent {
  final String? query;
  SearchProductsEvent(this.query);
}
