import 'package:equatable/equatable.dart';
import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';
import 'package:mobile/features/admin/domain/entities/color_entity.dart';
import 'package:mobile/features/admin/domain/entities/size_entity.dart';

abstract class AdminProductState extends Equatable {
  const AdminProductState();
  @override
  List<Object?> get props => [];
}

class AdminProductInitial extends AdminProductState {}

// Products List States
class AdminProductsLoading extends AdminProductState {}

class AdminProductsLoaded extends AdminProductState {
  final List<AdminProductEntity> products;
  const AdminProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class AdminProductsError extends AdminProductState {
  final String message;
  const AdminProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Product Details States
class AdminProductDetailsLoading extends AdminProductState {}

class AdminProductDetailsLoaded extends AdminProductState {
  final AdminProductEntity product;
  const AdminProductDetailsLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

class AdminProductDetailsError extends AdminProductState {
  final String message;
  const AdminProductDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Categories States
class AdminCategoriesLoading extends AdminProductState {}

class AdminCategoriesLoaded extends AdminProductState {
  final List<AdminCategoryEntity> categories;
  const AdminCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class AdminCategoriesError extends AdminProductState {
  final String message;
  const AdminCategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}

// Colors States
class AdminColorsLoading extends AdminProductState {}

class AdminColorsLoaded extends AdminProductState {
  final List<ColorEntity> colors;
  const AdminColorsLoaded(this.colors);

  @override
  List<Object?> get props => [colors];
}

// Sizes States
class AdminSizesLoading extends AdminProductState {}

class AdminSizesLoaded extends AdminProductState {
  final List<SizeEntity> sizes;
  const AdminSizesLoaded(this.sizes);

  @override
  List<Object?> get props => [sizes];
}

// Operation States
class AdminProductOperationSuccess extends AdminProductState {
  final String message;
  final String? productId;
  const AdminProductOperationSuccess(this.message, {this.productId});

  @override
  List<Object?> get props => [message, productId];
}

class AdminProductCreating extends AdminProductState {
  final String step; // 'creating', 'uploading_images', 'adding_variants'
  final int current;
  final int total;

  const AdminProductCreating({
    required this.step,
    this.current = 0,
    this.total = 0,
  });

  @override
  List<Object?> get props => [step, current, total];
}
