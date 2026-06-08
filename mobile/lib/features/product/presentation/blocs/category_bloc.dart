import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/domain/usecases/get_categories.dart';
import 'package:mobile/features/product/domain/usecases/get_category_by_id.dart';
import 'package:mobile/features/product/domain/usecases/get_parent_categories.dart';
import 'package:mobile/features/product/domain/usecases/get_subcategories.dart';

import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final GetCategories getCategories;
  final GetParentCategories getParentCategories;
  final GetSubcategories getSubcategories;
  final GetCategoryById getCategoryById;

  CategoryBloc({
    required this.getCategories,
    required this.getParentCategories,
    required this.getSubcategories,
    required this.getCategoryById,
  }) : super(CategoryInitial()) {
    on<GetCategoriesEvent>(_onGetCategories);
    on<GetParentCategoriesEvent>(_onGetParentCategories);
    on<GetSubcategoriesEvent>(_onGetSubcategories);
    on<GetCategoryByIdEvent>(_onGetCategoryById);
  }

  Future<void> _onGetCategories(
    GetCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoriesLoading());
    final result = await getCategories();
    result.fold(
      (failure) => emit(CategoriesError(failure.message)),
      (categories) => emit(CategoriesLoaded(categories)),
    );
  }

  Future<void> _onGetParentCategories(
    GetParentCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoriesLoading());
    final result = await getParentCategories();
    result.fold(
      (failure) => emit(CategoriesError(failure.message)),
      (categories) => emit(ParentCategoriesLoaded(categories)),
    );
  }

  Future<void> _onGetSubcategories(
    GetSubcategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoriesLoading());
    final result = await getSubcategories(event.parentId);
    result.fold(
      (failure) => emit(CategoriesError(failure.message)),
      (subcategories) => emit(SubcategoriesLoaded(subcategories)),
    );
  }

  Future<void> _onGetCategoryById(
    GetCategoryByIdEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoriesLoading());
    final result = await getCategoryById(event.id);
    result.fold(
      (failure) => emit(CategoriesError(failure.message)),
      (category) => emit(CategoryLoaded(category)),
    );
  }
}
