import 'package:flutter_bloc/flutter_bloc.dart';
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
  }

  Future<void> _onFetchTree(
    FetchCategoriesTreeEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    emit(AdminCategoriesLoading());
    try {
      final categories = await repository.getCategoriesTree();
      emit(AdminCategoriesLoaded(categories));
    } catch (e) {
      emit(AdminCategoriesError(e.toString()));
    }
  }

  Future<void> _onCreate(
    CreateCategoryEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    try {
      await repository.createCategory(event.data);
      emit(
        const AdminCategoryOperationSuccess('Category created successfully'),
      );
      add(FetchCategoriesTreeEvent());
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
      emit(
        const AdminCategoryOperationSuccess('Category updated successfully'),
      );
      add(FetchCategoriesTreeEvent());
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
      emit(
        const AdminCategoryOperationSuccess('Category deleted successfully'),
      );
      add(FetchCategoriesTreeEvent());
    } catch (e) {
      emit(AdminCategoriesError(e.toString()));
    }
  }
}
