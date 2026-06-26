import 'package:equatable/equatable.dart';
import 'package:mobile/features/admin/domain/entities/color_entity.dart';
import 'package:mobile/features/admin/domain/entities/size_entity.dart';

abstract class AdminColorSizeState extends Equatable {
  const AdminColorSizeState();
  @override
  List<Object?> get props => [];
}

class AdminColorSizeInitial extends AdminColorSizeState {}

// Colors States
class AdminColorsLoading extends AdminColorSizeState {}

class AdminColorsLoaded extends AdminColorSizeState {
  final List<ColorEntity> colors;
  const AdminColorsLoaded(this.colors);

  @override
  List<Object?> get props => [colors];
}

class AdminColorsError extends AdminColorSizeState {
  final String message;
  const AdminColorsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Sizes States
class AdminSizesLoading extends AdminColorSizeState {}

class AdminSizesLoaded extends AdminColorSizeState {
  final List<SizeEntity> sizes;
  const AdminSizesLoaded(this.sizes);

  @override
  List<Object?> get props => [sizes];
}

class AdminSizesError extends AdminColorSizeState {
  final String message;
  const AdminSizesError(this.message);

  @override
  List<Object?> get props => [message];
}

// Operation Success
class AdminColorSizeOperationSuccess extends AdminColorSizeState {
  final String message;
  const AdminColorSizeOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
