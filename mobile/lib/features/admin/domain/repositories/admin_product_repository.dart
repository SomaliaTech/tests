// lib/features/admin/domain/repositories/admin_product_repository.dart
import 'dart:io';
import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';
import 'package:mobile/features/admin/domain/entities/color_entity.dart';
import 'package:mobile/features/admin/domain/entities/size_entity.dart';

abstract class AdminProductRepository {
  Future<List<AdminProductEntity>> getAllProducts();
  Future<AdminProductEntity> getProductById(String productId);

  // ✅ Updated signature
  Future<String> createProduct(
    Map<String, dynamic> productData, {
    List<File> images,
  });

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updateData, {
    List<File> newImages,
    List<String> deletedImageIds,
    List<Map<String, dynamic>> existingVariants,
    List<Map<String, dynamic>> newVariants,
    List<String> deletedVariantIds,
  });

  Future<void> deleteProduct(String productId);
  Future<List<AdminCategoryEntity>> getCategoriesTree();
  Future<List<ColorEntity>> getColors();
  Future<List<SizeEntity>> getSizes();
  Future<void> uploadProductImage(String productId, String base64Image);
  Future<void> addProductVariant(
    String productId,
    Map<String, dynamic> variantData,
  );
}
