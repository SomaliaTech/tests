import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class GetCategoriesEvent extends CategoryEvent {}

class GetParentCategoriesEvent extends CategoryEvent {}

class GetSubcategoriesEvent extends CategoryEvent {
  final String parentId;
  const GetSubcategoriesEvent(this.parentId);

  @override
  List<Object?> get props => [parentId];
}

class GetCategoryByIdEvent extends CategoryEvent {
  final String id;
  const GetCategoryByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class GetCategoryBySlugEvent extends CategoryEvent {
  final String slug;
  const GetCategoryBySlugEvent(this.slug);

  @override
  List<Object?> get props => [slug];
}
