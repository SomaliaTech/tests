import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class GetCategoriesEvent extends CategoryEvent {}

class GetParentCategoriesEvent extends CategoryEvent {}

class GetCategorySubcategoriesEvent extends CategoryEvent {
  // Changed name to avoid conflict
  final String parentId;
  const GetCategorySubcategoriesEvent(this.parentId);

  @override
  List<Object?> get props => [parentId];
}

class GetCategoryByIdEvent extends CategoryEvent {
  final String id;
  const GetCategoryByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}
