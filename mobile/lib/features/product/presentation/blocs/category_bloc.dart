// lib/features/product/presentation/blocs/category_bloc.dart
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
    on<GetCategorySubcategoriesEvent>(_onGetSubcategories);
    on<GetCategoryByIdEvent>(_onGetCategoryById);
  }

  // 🚀 Categories - Show cached first, don't show loading if we have data
  Future<void> _onGetCategories(
    GetCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    final currentState = state;
    // Only show loading if we don't have categories loaded
    if (currentState is! CategoriesLoaded) {
      emit(CategoriesLoading());
    }

    final result = await getCategories();
    result.fold((failure) {
      if (currentState is! CategoriesLoaded) {
        emit(CategoryError(failure.message));
      }
    }, (categories) => emit(CategoriesLoaded(categories)));
  }

  // 🚀 Parent Categories - Show cached first
  Future<void> _onGetParentCategories(
    GetParentCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ParentCategoriesLoaded) {
      emit(CategoriesLoading());
    }

    final result = await getParentCategories();
    result.fold((failure) {
      if (currentState is! ParentCategoriesLoaded) {
        emit(CategoryError(failure.message));
      }
    }, (categories) => emit(ParentCategoriesLoaded(categories)));
  }

  // 🚀 Subcategories - Show cached first
  Future<void> _onGetSubcategories(
    GetCategorySubcategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategorySubcategoriesLoading());
    final result = await getSubcategories(event.parentId);
    result.fold(
      (failure) => emit(CategoryError(failure.message)),
      (subcategories) => emit(CategorySubcategoriesLoaded(subcategories)),
    );
  }

  // 🚀 Category by ID - Show cached first
  Future<void> _onGetCategoryById(
    GetCategoryByIdEvent event,
    Emitter<CategoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CategoryLoaded) {
      emit(CategoriesLoading());
    }

    final result = await getCategoryById(event.id);
    result.fold((failure) {
      if (currentState is! CategoryLoaded) {
        emit(CategoryError(failure.message));
      }
    }, (category) => emit(CategoryLoaded(category)));
  }
}
