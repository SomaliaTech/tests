// lib/features/admin/presentation/bloc/admin_category/admin_category_event.dart

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

class DeleteCategoryWithTransferEvent extends AdminCategoryEvent {
  final String categoryId;
  final String targetCategoryId;

  const DeleteCategoryWithTransferEvent({
    required this.categoryId,
    required this.targetCategoryId,
  });

  @override
  List<Object?> get props => [categoryId, targetCategoryId];
}

class FetchCategoriesForTransferEvent extends AdminCategoryEvent {}

// ✅ NEW: Cancel delete event
class CancelDeleteEvent extends AdminCategoryEvent {}
