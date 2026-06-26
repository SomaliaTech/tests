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
