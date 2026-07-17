// lib/features/admin/presentation/bloc/admin_category/admin_category_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';
import 'package:mobile/features/admin/domain/repositories/admin_category_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_category/admin_category_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_category/admin_category_state.dart';

class AdminCategoryBloc extends Bloc<AdminCategoryEvent, AdminCategoryState> {
  final AdminCategoryRepository repository;

  AdminCategoryBloc({required this.repository})
    : super(AdminCategoryInitial()) {
    on<FetchCategoriesTreeEvent>(_onFetchTree);
    on<CreateCategoryEvent>(_onCreate);
    on<UpdateCategoryEvent>(_onUpdate);
    on<DeleteCategoryEvent>(_onDelete);
    on<DeleteCategoryWithTransferEvent>(_onDeleteWithTransfer);
    on<FetchCategoriesForTransferEvent>(_onFetchForTransfer);
    on<CancelDeleteEvent>(_onCancelDelete); // ✅ NEW
  }

  Future<void> _onFetchTree(
    FetchCategoriesTreeEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    final currentState = state;
    // Only show loading if we don't have data
    if (currentState is! AdminCategoriesLoaded) {
      emit(AdminCategoriesLoading());
    }

    try {
      final categories = await repository.getCategoriesTree();
      emit(AdminCategoriesLoaded(categories));
    } catch (e) {
      if (currentState is AdminCategoriesLoaded) {
        return; // Keep existing data on silent refresh fail
      }
      emit(AdminCategoriesError(e.toString()));
    }
  }

  Future<void> _onCreate(
    CreateCategoryEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    // ✅ Don't emit loading - just do the operation silently
    try {
      await repository.createCategory(event.data);
      // Reload silently
      final categories = await repository.getCategoriesTree();
      emit(AdminCategoryOperationSuccess('Category created successfully'));
      emit(AdminCategoriesLoaded(categories));
    } catch (e) {
      emit(AdminCategoriesError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateCategoryEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    try {
      await repository.updateCategory(event.categoryId, event.data);
      final categories = await repository.getCategoriesTree();
      emit(AdminCategoryOperationSuccess('Category updated successfully'));
      emit(AdminCategoriesLoaded(categories));
    } catch (e) {
      emit(AdminCategoriesError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteCategoryEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    // ✅ Store current state before attempting delete
    final previousState = state;

    try {
      await repository.deleteCategory(event.categoryId);
      // Success - reload
      final categories = await repository.getCategoriesTree();
      emit(AdminCategoryOperationSuccess('Category deleted successfully'));
      emit(AdminCategoriesLoaded(categories));
    } catch (e) {
      print('❌ [AdminCategoryBloc] Delete failed: $e');
      final errorMessage = e.toString();

      // Check if category has subcategories or products
      if (errorMessage.contains('subcategories') ||
          errorMessage.contains('products') ||
          errorMessage.contains('Cannot delete')) {
        // ✅ CRITICAL: First restore previous state (keep screen working)
        if (previousState is AdminCategoriesLoaded) {
          emit(previousState);
        }

        // Then emit has products state for dialog
        // Use a microtask to ensure the previous state is processed first
        await Future.microtask(() {});
        emit(
          AdminCategoryHasProducts(
            categoryId: event.categoryId,
            message: errorMessage,
          ),
        );
      } else {
        // Other error - restore previous state first
        if (previousState is AdminCategoriesLoaded) {
          emit(previousState);
        }
        emit(AdminCategoriesError(errorMessage));
      }
    }
  }

  Future<void> _onDeleteWithTransfer(
    DeleteCategoryWithTransferEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    final previousState = state;

    try {
      await repository.deleteCategoryWithTransfer(
        event.categoryId,
        event.targetCategoryId,
      );
      final categories = await repository.getCategoriesTree();
      emit(
        AdminCategoryOperationSuccess(
          'Category deleted and products transferred',
        ),
      );
      emit(AdminCategoriesLoaded(categories));
    } catch (e) {
      // Restore previous state on error
      if (previousState is AdminCategoriesLoaded) {
        emit(previousState);
      }
      emit(AdminCategoriesError(e.toString()));
    }
  }

  Future<void> _onFetchForTransfer(
    FetchCategoriesForTransferEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    try {
      final categories = await repository.getAllCategories();
      emit(AdminCategoriesForTransfer(categories));
    } catch (e) {
      emit(AdminCategoriesError(e.toString()));
    }
  }

  // ✅ NEW: Handle cancel delete - restore to loaded state
  Future<void> _onCancelDelete(
    CancelDeleteEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    try {
      final categories = await repository.getCategoriesTree();
      emit(AdminCategoriesLoaded(categories));
    } catch (e) {
      // If reload fails, at least try to emit what we had
      emit(AdminCategoriesError(e.toString()));
    }
  }
}
