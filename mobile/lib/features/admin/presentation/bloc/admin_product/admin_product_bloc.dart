import 'dart:convert';
import 'dart:io';
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

  Future<void> _onCreate(
    CreateAdminProductEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      // Step 1: Create product
      emit(const AdminProductCreating(step: 'creating'));
      final productId = await repository.createProduct(event.productData);

      // Step 2: Upload images
      if (event.images.isNotEmpty) {
        for (int i = 0; i < event.images.length; i++) {
          emit(
            AdminProductCreating(
              step: 'uploading_images',
              current: i + 1,
              total: event.images.length,
            ),
          );
          final bytes = await event.images[i].readAsBytes();
          final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          await repository.uploadProductImage(productId, base64Image);
        }
      }

      // Step 3: Add variants
      if (event.variants.isNotEmpty) {
        for (int i = 0; i < event.variants.length; i++) {
          emit(
            AdminProductCreating(
              step: 'adding_variants',
              current: i + 1,
              total: event.variants.length,
            ),
          );
          await repository.addProductVariant(productId, event.variants[i]);
        }
      }

      emit(
        AdminProductOperationSuccess(
          'Product created successfully',
          productId: productId,
        ),
      );
      add(FetchAllAdminProductsEvent());
    } catch (e) {
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

  Future<void> _onUpdate(
    UpdateAdminProductEvent event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      // Step 1: Update product
      emit(const AdminProductCreating(step: 'updating'));
      await repository.updateProduct(event.productId, event.updateData);

      // Step 2: Delete removed images
      if (event.deletedImageIds.isNotEmpty) {
        for (int i = 0; i < event.deletedImageIds.length; i++) {
          emit(
            AdminProductCreating(
              step: 'deleting_images',
              current: i + 1,
              total: event.deletedImageIds.length,
            ),
          );
          // You'll need to add deleteImage method to repository
          // await repository.deleteProductImage(event.productId, event.deletedImageIds[i]);
        }
      }

      // Step 3: Upload new images
      if (event.newImages.isNotEmpty) {
        for (int i = 0; i < event.newImages.length; i++) {
          emit(
            AdminProductCreating(
              step: 'uploading_images',
              current: i + 1,
              total: event.newImages.length,
            ),
          );
          final bytes = await event.newImages[i].readAsBytes();
          final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          await repository.uploadProductImage(event.productId, base64Image);
        }
      }

      // Step 4: Add new variants
      if (event.newVariants.isNotEmpty) {
        for (int i = 0; i < event.newVariants.length; i++) {
          emit(
            AdminProductCreating(
              step: 'adding_variants',
              current: i + 1,
              total: event.newVariants.length,
            ),
          );
          await repository.addProductVariant(
            event.productId,
            event.newVariants[i],
          );
        }
      }

      emit(AdminProductOperationSuccess('Product updated successfully'));
      add(FetchAllAdminProductsEvent());
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
