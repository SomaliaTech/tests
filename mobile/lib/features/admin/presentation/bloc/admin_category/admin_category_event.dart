import 'package:equatable/equatable.dart';

abstract class AdminCategoryEvent extends Equatable {
  const AdminCategoryEvent();
  @override
  List<Object?> get props => [];
}

class FetchCategoriesTreeEvent extends AdminCategoryEvent {}

class CreateCategoryEvent extends AdminCategoryEvent {
  final Map<String, dynamic> data;
  const CreateCategoryEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateCategoryEvent extends AdminCategoryEvent {
  final String categoryId;
  final Map<String, dynamic> data;
  const UpdateCategoryEvent(this.categoryId, this.data);

  @override
  List<Object?> get props => [categoryId, data];
}

class DeleteCategoryEvent extends AdminCategoryEvent {
  final String categoryId;
  const DeleteCategoryEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}
