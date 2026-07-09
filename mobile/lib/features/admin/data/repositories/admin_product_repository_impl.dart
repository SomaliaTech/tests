// lib/features/admin/data/repositories/admin_product_repository_impl.dart
import 'dart:io';
import 'package:mobile/features/admin/data/datasources/admin_product_remote_data_source.dart';
import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';
import 'package:mobile/features/admin/domain/entities/color_entity.dart';
import 'package:mobile/features/admin/domain/entities/size_entity.dart';
import 'package:mobile/features/admin/domain/repositories/admin_product_repository.dart';

class AdminProductRepositoryImpl implements AdminProductRepository {
  final AdminProductRemoteDataSource remoteDataSource;

  AdminProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AdminProductEntity>> getAllProducts() async {
    final models = await remoteDataSource.getAllProducts();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<AdminProductEntity> getProductById(String productId) async {
    final model = await remoteDataSource.getProductById(productId);
    return model.toEntity();
  }

  @override
  Future<String> createProduct(
    Map<String, dynamic> productData, {
    List<File> images = const [],
  }) async {
    // ✅ Just delegate to remote data source
    return await remoteDataSource.createProduct(productData, images: images);
  }

  @override
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updateData, {
    List<File> newImages = const [],
    List<String> deletedImageIds = const [],
    List<Map<String, dynamic>> existingVariants = const [],
    List<Map<String, dynamic>> newVariants = const [],
    List<String> deletedVariantIds = const [],
  }) async {
    await remoteDataSource.updateProduct(
      productId,
      updateData,
      newImages: newImages,
      deletedImageIds: deletedImageIds,
      existingVariants: existingVariants,
      newVariants: newVariants,
      deletedVariantIds: deletedVariantIds,
    );
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await remoteDataSource.deleteProduct(productId);
  }

  @override
  Future<List<AdminCategoryEntity>> getCategoriesTree() async {
    final models = await remoteDataSource.getCategoriesTree();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<ColorEntity>> getColors() async {
    final models = await remoteDataSource.getColors();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<SizeEntity>> getSizes() async {
    final models = await remoteDataSource.getSizes();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> uploadProductImage(String productId, String base64Image) async {
    await remoteDataSource.uploadProductImage(productId, base64Image);
  }

  @override
  Future<void> addProductVariant(
    String productId,
    Map<String, dynamic> variantData,
  ) async {
    await remoteDataSource.addProductVariant(productId, variantData);
  }
}
