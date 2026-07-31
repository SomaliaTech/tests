// lib/features/admin/presentation/bloc/admin_product/admin_product_bloc.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/domain/repositories/admin_product_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_state.dart';

class AdminProductBloc extends Bloc<AdminProductEvent, AdminProductState> {
  final AdminProductRepository repository;

  AdminProductBloc({required this.repository}) : super(AdminProductInitial()) {
    on<FetchAllAdminProductsEvent>(_onFetchAll);
    on<FetchAdminProductByIdEvent>(_onFetchById);
    on<CreateAdminProductEvent>(_onCreate);
    on<UpdateAdminProductEvent>(_onUpdate);
    on<DeleteAdminProductEvent>(_onDelete);
    on<FetchCategoriesTreeEvent>(_onFetchCategories);
    on<FetchColorsEvent>(_onFetchColors);
    on<FetchSizesEvent>(_onFetchSizes);
    on<SilentFetchAllAdminProductsEvent>(_onSilentFetch);
  }

  Future<void> _onFetchAll(
    FetchAllAdminProductsEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    debugPrint('📦 [AdminProductBloc] Fetching all products...');
    emit(AdminProductsLoading());
    try {
      final products = await repository.getAllProducts();
      debugPrint('📦 [AdminProductBloc] Loaded ${products.length} products');
      emit(AdminProductsLoaded(products));
    } catch (e) {
      debugPrint('❌ [AdminProductBloc] Error fetching products: $e');
      emit(AdminProductsError(e.toString()));
    }
  }

  Future<void> _onFetchById(
    FetchAdminProductByIdEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    debugPrint('🔍 [AdminProductBloc] Fetching product: ${event.productId}');
    emit(AdminProductDetailsLoading());
    try {
      final product = await repository.getProductById(event.productId);
      debugPrint('✅ [AdminProductBloc] Product loaded: ${product.name}');
      emit(AdminProductDetailsLoaded(product));
    } catch (e) {
      debugPrint('❌ [AdminProductBloc] Error fetching product: $e');
      emit(AdminProductDetailsError(e.toString()));
    }
  }

  Future<void> _onCreate(
    CreateAdminProductEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      emit(const AdminProductCreating(step: 'creating'));
      final productData = Map<String, dynamic>.from(event.productData);
      if (event.variants.isNotEmpty) {
        productData['variants'] = event.variants;
      }
      await repository.createProduct(productData, images: event.images);
      emit(const AdminProductOperationSuccess('Product created successfully'));

      // ❌ REMOVE THIS:
      // Future.delayed(const Duration(milliseconds: 300), () {
      //   add(FetchAllAdminProductsEvent());
      // });
    } catch (e) {
      debugPrint('❌ [Bloc] Create product error: $e');
      emit(AdminProductsError(e.toString()));
    }
  }

  Future<void> _onSilentFetch(
    SilentFetchAllAdminProductsEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      // ✅ NO loading state emitted — products stay visible
      final products = await repository.getAllProducts();
      emit(AdminProductsLoaded(products));
    } catch (e) {
      debugPrint('❌ [Bloc] Silent fetch error: $e');
      // Don't emit error — keep existing list visible
    }
  }

  Future<void> _onDelete(
    DeleteAdminProductEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      debugPrint('🗑️ [AdminProductBloc] Deleting product: ${event.productId}');
      await repository.deleteProduct(event.productId);
      emit(const AdminProductOperationSuccess('Product deleted successfully'));

      // ❌ REMOVE THIS:
      // Future.delayed(const Duration(milliseconds: 300), () {
      //   add(FetchAllAdminProductsEvent());
      // });
    } catch (e) {
      debugPrint('❌ [AdminProductBloc] Error deleting product: $e');
      emit(AdminProductsError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateAdminProductEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      debugPrint('✏️ [AdminProductBloc] Updating product: ${event.productId}');
      emit(const AdminProductCreating(step: 'updating'));

      await repository.updateProduct(
        event.productId,
        event.updateData,
        newImages: event.newImages,
        deletedImageIds: event.deletedImageIds,
        existingVariants: event.existingVariants,
        newVariants: event.newVariants,
        deletedVariantIds: event.deletedVariantIds,
      );

      emit(const AdminProductOperationSuccess('Product updated successfully'));

      // ❌ REMOVE THIS:
      // Future.delayed(const Duration(milliseconds: 300), () {
      //   add(FetchAllAdminProductsEvent());
      // });
    } catch (e) {
      debugPrint('❌ [Bloc] Update product error: $e');
      emit(AdminProductsError(e.toString()));
    }
  }

  Future<void> _onFetchCategories(
    FetchCategoriesTreeEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    emit(AdminCategoriesLoading());
    try {
      final categories = await repository.getCategoriesTree();
      emit(AdminCategoriesLoaded(categories));
    } catch (e) {
      emit(AdminCategoriesError(e.toString()));
    }
  }

  Future<void> _onFetchColors(
    FetchColorsEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    emit(AdminColorsLoading());
    try {
      final colors = await repository.getColors();
      emit(AdminColorsLoaded(colors));
    } catch (e) {
      emit(AdminProductsError(e.toString()));
    }
  }

  Future<void> _onFetchSizes(
    FetchSizesEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    emit(AdminSizesLoading());
    try {
      final sizes = await repository.getSizes();
      emit(AdminSizesLoaded(sizes));
    } catch (e) {
      emit(AdminProductsError(e.toString()));
    }
  }
}
