// lib/features/admin/domain/repositories/admin_category_repository.dart

import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';

abstract class AdminCategoryRepository {
  Future<List<AdminCategoryEntity>> getCategoriesTree();
  Future<List<AdminCategoryEntity>> getAllCategories(); // ✅ NEW
  Future<void> createCategory(Map<String, dynamic> data);
  Future<void> updateCategory(String categoryId, Map<String, dynamic> data);
  Future<void> deleteCategory(String categoryId);
  Future<void> deleteCategoryWithTransfer(
    String categoryId,
    String targetCategoryId,
  ); // ✅ NEW
}
