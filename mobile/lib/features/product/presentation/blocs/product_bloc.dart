import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/domain/usecases/get_categories.dart';
import 'package:mobile/features/product/domain/usecases/get_featured_products.dart';
import 'package:mobile/features/product/domain/usecases/get_products_by_category.dart';
import 'package:mobile/features/product/domain/usecases/search_products.dart';

import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetCategories getCategories;
  final GetFeaturedProducts getFeaturedProducts;
  final GetProductsByCategory getProductsByCategory;
  final SearchProducts searchProducts;

  ProductBloc({
    required this.getCategories,
    required this.getFeaturedProducts,
    required this.getProductsByCategory,
    required this.searchProducts,
  }) : super(ProductInitial()) {
    on<GetCategoriesEvent>((event, emit) async {
      emit(ProductLoading());
      try {
        final categories = await getCategories();
        emit(CategoriesLoaded(categories));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });

    on<GetFeaturedProductsEvent>((event, emit) async {
      emit(ProductLoading());
      try {
        final products = await getFeaturedProducts(limit: 10);
        emit(ProductsLoaded(products));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });

    on<GetProductsByCategoryEvent>((event, emit) async {
      emit(ProductLoading());
      try {
        final products = await getProductsByCategory(event.categoryId);
        emit(ProductsLoaded(products));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });

    on<SearchProductsEvent>((event, emit) async {
      emit(ProductLoading());
      try {
        final products = await searchProducts(query: event.query);
        emit(ProductsLoaded(products));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });
  }
}
