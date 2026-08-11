// lib/features/product/presentation/blocs/product_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/domain/usecases/get_categories.dart';
import 'package:mobile/features/product/domain/usecases/get_featured_products.dart';
import 'package:mobile/features/product/domain/usecases/get_latest_products.dart';
import 'package:mobile/features/product/domain/usecases/get_product_by_id.dart';
import 'package:mobile/features/product/domain/usecases/get_products_by_category.dart';
import 'package:mobile/features/product/domain/usecases/get_subcategories.dart';
import 'package:mobile/features/product/domain/usecases/search_products.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetCategories getCategories;
  final GetSubcategories getSubcategories;
  final GetFeaturedProducts getFeaturedProducts;
  final GetProductsByCategory getProductsByCategory;
  final SearchProducts searchProducts;
  final GetProductById getProductById;
  final GetLatestProducts getLatestProducts; // ✅ Added field

  ProductBloc({
    required this.getCategories,
    required this.getSubcategories,
    required this.getFeaturedProducts,
    required this.getProductsByCategory,
    required this.getLatestProducts, // ✅ Added to constructor

    required this.searchProducts,
    required this.getProductById,
  }) : super(ProductInitial()) {
    on<GetCategoriesEvent>(_onGetCategories);
    on<GetSubcategoriesEvent>(_onGetSubcategories);
    on<GetFeaturedProductsEvent>(_onGetFeaturedProducts);
    on<GetProductsByCategoryEvent>(_onGetProductsByCategory);
    on<SearchProductsEvent>(_onSearchProducts);
    on<GetProductByIdEvent>(_onGetProductById);
    on<GetLatestProductsEvent>(_onGetLatestProducts);
  }

  // ✅ Helper to create user-friendly error messages
  String _getFriendlyErrorMessage(String originalError) {
    final error = originalError.toLowerCase();

    if (error.contains('internet') ||
        error.contains('network') ||
        error.contains('connection') ||
        error.contains('socketexception') ||
        error.contains('unreachable') ||
        error.contains('timeout')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error.contains('server') ||
        error.contains('500') ||
        error.contains('502')) {
      return 'Server is temporarily unavailable. Please try again later.';
    }

    if (error.contains('404') || error.contains('not found')) {
      return 'The requested item was not found.';
    }

    if (error.contains('unauthorized') || error.contains('401')) {
      return 'Your session has expired. Please login again.';
    }

    return 'Something went wrong. Please try again.';
  }

  // 🚀 Categories - Show cached first, skip loading if data exists
  Future<void> _onGetCategories(
    GetCategoriesEvent event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CategoriesLoaded) {
      emit(CategoriesLoading());
    }

    final result = await getCategories();
    if (emit.isDone) return;

    result.fold((failure) {
      if (currentState is! CategoriesLoaded) {
        emit(CategoriesError(_getFriendlyErrorMessage(failure.message)));
      }
    }, (categories) => emit(CategoriesLoaded(categories)));
  }

  Future<void> _onGetSubcategories(
    GetSubcategoriesEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(SubcategoriesLoading());
    final result = await getSubcategories(event.parentId);
    if (emit.isDone) return;

    result.fold(
      (failure) =>
          emit(SubcategoriesError(_getFriendlyErrorMessage(failure.message))),
      (subcategories) => emit(SubcategoriesLoaded(subcategories)),
    );
  }

  Future<void> _onGetLatestProducts(
    GetLatestProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    if (event.forceRefresh) {
      emit(LatestProductsLoading());
    } else {
      final currentState = state;
      if (currentState is! LatestProductsLoaded) {
        emit(LatestProductsLoading());
      }
    }

    // Assuming you created the GetLatestProducts usecase
    final result = await getLatestProducts(limit: event.limit ?? 10);
    if (emit.isDone) return;

    result.fold((failure) {
      if (state is! LatestProductsLoaded || event.forceRefresh) {
        emit(LatestProductsError(_getFriendlyErrorMessage(failure.message)));
      }
    }, (products) => emit(LatestProductsLoaded(products)));
  }

  // In ProductBloc, update _onGetFeaturedProducts
  Future<void> _onGetFeaturedProducts(
    GetFeaturedProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    // ✅ If force refresh, always show loading
    if (event.forceRefresh) {
      emit(FeaturedProductsLoading());
    } else {
      final currentState = state;
      if (currentState is! FeaturedProductsLoaded) {
        emit(FeaturedProductsLoading());
      }
    }

    final result = await getFeaturedProducts(limit: event.limit ?? 10);
    if (emit.isDone) return;

    result.fold((failure) {
      if (state is! FeaturedProductsLoaded || event.forceRefresh) {
        emit(FeaturedProductsError(failure.message));
      }
    }, (products) => emit(FeaturedProductsLoaded(products)));
  }

  // 🚀 Products by Category - Show cached first
  Future<void> _onGetProductsByCategory(
    GetProductsByCategoryEvent event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProductsLoaded) {
      emit(ProductLoading());
    }

    final result = await getProductsByCategory(event.categoryId);
    if (emit.isDone) return;

    result.fold((failure) {
      if (currentState is! ProductsLoaded) {
        emit(ProductError(_getFriendlyErrorMessage(failure.message)));
      }
    }, (products) => emit(ProductsLoaded(products)));
  }

  // Search - Always show loading (no cache for search)
  Future<void> _onSearchProducts(
    SearchProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await searchProducts(
      query: event.query,
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
      categoryId: event.categoryId,
      sortBy: event.sortBy,
    );
    if (emit.isDone) return;

    result.fold(
      (failure) =>
          emit(ProductError(_getFriendlyErrorMessage(failure.message))),
      (products) => emit(ProductsLoaded(products)),
    );
  }

  // 🚀 Product Detail - Show cached first
  Future<void> _onGetProductById(
    GetProductByIdEvent event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProductDetailLoaded) {
      emit(ProductDetailLoading());
    }

    final result = await getProductById(event.productId);
    if (emit.isDone) return;

    result.fold((failure) {
      if (currentState is! ProductDetailLoaded) {
        emit(ProductDetailError(_getFriendlyErrorMessage(failure.message)));
      }
    }, (product) => emit(ProductDetailLoaded(product)));
  }
}
