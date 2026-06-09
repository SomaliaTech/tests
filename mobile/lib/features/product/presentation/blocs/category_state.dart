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

class CategorySubcategoriesLoading extends CategoryState {} // Changed name

class CategorySubcategoriesLoaded extends CategoryState {
  // Changed name
  final List<Category> subcategories;
  const CategorySubcategoriesLoaded(this.subcategories);

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
class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
