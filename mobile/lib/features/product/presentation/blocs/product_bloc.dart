import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/domain/usecases/get_categories.dart';
import 'package:mobile/features/product/domain/usecases/get_featured_products.dart';
import 'package:mobile/features/product/domain/usecases/get_product_by_id.dart';
import 'package:mobile/features/product/domain/usecases/get_products_by_category.dart';
import 'package:mobile/features/product/domain/usecases/search_products.dart';

import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetCategories getCategories;
  final GetFeaturedProducts getFeaturedProducts;
  final GetProductsByCategory getProductsByCategory;
  final SearchProducts searchProducts;
  final GetProductById getProductById;

  ProductBloc({
    required this.getCategories,
    required this.getFeaturedProducts,
    required this.getProductsByCategory,
    required this.searchProducts,
    required this.getProductById,
  }) : super(ProductInitial()) {
    on<GetCategoriesEvent>((event, emit) async {
      emit(CategoriesLoading());
      final result = await getCategories();
      result.fold(
        (failure) => emit(CategoriesError(failure.message)),
        (categories) => emit(CategoriesLoaded(categories)),
      );
    });

    on<GetFeaturedProductsEvent>((event, emit) async {
      emit(FeaturedProductsLoading());
      final result = await getFeaturedProducts(limit: 10);
      result.fold(
        (failure) => emit(FeaturedProductsError(failure.message)),
        (products) => emit(FeaturedProductsLoaded(products)),
      );
    });

    on<GetProductsByCategoryEvent>((event, emit) async {
      emit(ProductLoading());
      final result = await getProductsByCategory(event.categoryId);
      result.fold(
        (failure) => emit(ProductError(failure.message)),
        (products) => emit(ProductsLoaded(products)),
      );
    });

    on<SearchProductsEvent>((event, emit) async {
      emit(ProductLoading());
      final result = await searchProducts(query: event.query);
      result.fold(
        (failure) => emit(ProductError(failure.message)),
        (products) => emit(ProductsLoaded(products)),
      );
    });

    on<GetProductByIdEvent>((event, emit) async {
      emit(ProductDetailLoading());
      final result = await getProductById(event.productId);
      result.fold(
        (failure) => emit(ProductDetailError(failure.message)),
        (product) => emit(ProductDetailLoaded(product)),
      );
    });
  }
}
