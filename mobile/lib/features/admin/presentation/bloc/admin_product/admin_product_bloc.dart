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
  }

  Future<void> _onFetchAll(
    FetchAllAdminProductsEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    emit(AdminProductsLoading());
    try {
      final products = await repository.getAllProducts();
      emit(AdminProductsLoaded(products));
    } catch (e) {
      emit(AdminProductsError(e.toString()));
    }
  }

  Future<void> _onFetchById(
    FetchAdminProductByIdEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    emit(AdminProductDetailsLoading());
    try {
      final product = await repository.getProductById(event.productId);
      emit(AdminProductDetailsLoaded(product));
    } catch (e) {
      emit(AdminProductDetailsError(e.toString()));
    }
  }

  // In AdminProductBloc - _onCreate method
  Future<void> _onCreate(
    CreateAdminProductEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      emit(const AdminProductCreating(step: 'creating'));

      final productData = Map<String, dynamic>.from(event.productData);
      if (event.variants.isNotEmpty) {
        productData['variants'] = event.variants.map((v) {
          final clean = {'colorId': v['colorId'], 'sizeId': v['sizeId']};
          if (v['stock'] != null) clean['stock'] = v['stock'];
          if (v['price'] != null) clean['price'] = v['price'];
          if (v['sku'] != null) clean['sku'] = v['sku'];
          return clean;
        }).toList();
      }

      debugPrint(
        '📦 [Bloc] Creating product with ${event.variants.length} variants and ${event.images.length} images',
      );

      // ✅ Send everything in ONE multipart request
      final productId = await repository.createProduct(
        productData,
        images: event.images,
      );

      emit(
        AdminProductOperationSuccess(
          'Product created successfully',
          productId: productId,
        ),
      );
      add(FetchAllAdminProductsEvent());
    } catch (e) {
      debugPrint('❌ [Bloc] Create product error: $e');
      emit(AdminProductsError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteAdminProductEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      await repository.deleteProduct(event.productId);
      emit(const AdminProductOperationSuccess('Product deleted successfully'));
      add(FetchAllAdminProductsEvent());
    } catch (e) {
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

  // In AdminProductBloc - Updated _onUpdate method
  Future<void> _onUpdate(
    UpdateAdminProductEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      emit(const AdminProductCreating(step: 'updating'));

      // ✅ Send everything in ONE request
      await repository.updateProduct(
        event.productId,
        event.updateData,
        newImages: event.newImages,
        deletedImageIds: event.deletedImageIds,
        existingVariants: event.existingVariants,
        newVariants: event.newVariants,
        deletedVariantIds: event.deletedVariantIds,
      );

      emit(AdminProductOperationSuccess('Product updated successfully'));
      add(FetchAllAdminProductsEvent());
    } catch (e) {
      debugPrint('❌ [Bloc] Update product error: $e');
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
