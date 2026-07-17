// lib/features/admin/presentation/bloc/admin_category/admin_category_state.dart

import 'package:equatable/equatable.dart';
import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';

abstract class AdminCategoryState extends Equatable {
  const AdminCategoryState();
  @override
  List<Object?> get props => [];
}

class AdminCategoryInitial extends AdminCategoryState {}

class AdminCategoriesLoading extends AdminCategoryState {}

class AdminCategoriesLoaded extends AdminCategoryState {
  final List<AdminCategoryEntity> categories;
  const AdminCategoriesLoaded(this.categories);
  @override
  List<Object?> get props => [categories];
}

class AdminCategoriesError extends AdminCategoryState {
  final String message;
  const AdminCategoriesError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminCategoryOperationSuccess extends AdminCategoryState {
  final String message;
  const AdminCategoryOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminCategoryHasProducts extends AdminCategoryState {
  final String categoryId;
  final String message;
  const AdminCategoryHasProducts({
    required this.categoryId,
    required this.message,
  });
  @override
  List<Object?> get props => [categoryId, message];
}

class AdminCategoriesForTransfer extends AdminCategoryState {
  final List<AdminCategoryEntity> categories;
  const AdminCategoriesForTransfer(this.categories);
  @override
  List<Object?> get props => [categories];
}
