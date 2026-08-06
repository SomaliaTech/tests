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
    try {
      await repository.createCategory(event.data);
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
    try {
      await repository.deleteCategory(event.categoryId);
      final categories = await repository.getCategoriesTree();
      emit(AdminCategoryOperationSuccess('Category deleted successfully'));
      emit(AdminCategoriesLoaded(categories));
    } catch (e) {
      print('❌ [AdminCategoryBloc] Delete failed: $e');
      final errorMessage = e.toString();

      if (errorMessage.contains('subcategories') ||
          errorMessage.contains('products') ||
          errorMessage.contains('Cannot delete')) {
        emit(
          AdminCategoryHasProducts(
            categoryId: event.categoryId,
            message: errorMessage,
          ),
        );
      } else {
        emit(AdminCategoriesError(errorMessage));
      }
    }
  }

  Future<void> _onDeleteWithTransfer(
    DeleteCategoryWithTransferEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    try {
      await repository.deleteCategoryWithTransfer(
        event.categoryId,
        event.targetCategoryId,
      );

      // Emit loading first to trigger dialog close
      emit(AdminCategoriesLoading());

      // Small delay to ensure dialog closes properly
      await Future.delayed(const Duration(milliseconds: 100));

      final categories = await repository.getCategoriesTree();
      emit(
        AdminCategoryOperationSuccess(
          'Category deleted and products transferred',
        ),
      );
      emit(AdminCategoriesLoaded(categories));
    } catch (e) {
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
}
