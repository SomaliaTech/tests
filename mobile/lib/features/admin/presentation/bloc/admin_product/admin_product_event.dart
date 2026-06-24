import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class AdminProductEvent extends Equatable {
  const AdminProductEvent();
  @override
  List<Object?> get props => [];
}

class FetchAllAdminProductsEvent extends AdminProductEvent {}

class FetchAdminProductByIdEvent extends AdminProductEvent {
  final String productId;
  const FetchAdminProductByIdEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class CreateAdminProductEvent extends AdminProductEvent {
  final Map<String, dynamic> productData;
  final List<File> images;
  final List<Map<String, dynamic>> variants;

  const CreateAdminProductEvent({
    required this.productData,
    this.images = const [],
    this.variants = const [],
  });

  @override
  List<Object?> get props => [productData, images, variants];
}

class UpdateAdminProductEvent extends AdminProductEvent {
  final String productId;
  final Map<String, dynamic> updateData;
  final List<File> newImages;
  final List<String> deletedImageIds;
  final List<Map<String, dynamic>> newVariants;

  const UpdateAdminProductEvent({
    required this.productId,
    required this.updateData,
    this.newImages = const [],
    this.deletedImageIds = const [],
    this.newVariants = const [],
  });

  @override
  List<Object?> get props => [
    productId,
    updateData,
    newImages,
    deletedImageIds,
    newVariants,
  ];
}

class DeleteAdminProductEvent extends AdminProductEvent {
  final String productId;
  const DeleteAdminProductEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class FetchCategoriesTreeEvent extends AdminProductEvent {}

class FetchColorsEvent extends AdminProductEvent {}

class FetchSizesEvent extends AdminProductEvent {}
