import 'package:equatable/equatable.dart';
import '../../domain/entities/category.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

// Loading States
class CategoriesLoading extends CategoryState {}

// Loaded States
class CategoriesLoaded extends CategoryState {
  final List<Category> categories;
  const CategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class ParentCategoriesLoaded extends CategoryState {
  final List<Category> categories;
  const ParentCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class SubcategoriesLoaded extends CategoryState {
  final List<Category> subcategories;
  const SubcategoriesLoaded(this.subcategories);

  @override
  List<Object?> get props => [subcategories];
}

class CategoryLoaded extends CategoryState {
  final Category category;
  const CategoryLoaded(this.category);

  @override
  List<Object?> get props => [category];
}

// Error States
class CategoriesError extends CategoryState {
  final String message;
  const CategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}
