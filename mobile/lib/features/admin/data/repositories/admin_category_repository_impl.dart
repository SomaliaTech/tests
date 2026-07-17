// lib/features/admin/data/repositories/admin_category_repository_impl.dart

import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/admin/data/datasources/admin_category_remote_data_source.dart';
import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';
import 'package:mobile/features/admin/domain/repositories/admin_category_repository.dart';

class AdminCategoryRepositoryImpl implements AdminCategoryRepository {
  final AdminCategoryRemoteDataSource remoteDataSource;

  AdminCategoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AdminCategoryEntity>> getCategoriesTree() async {
    try {
      return await remoteDataSource.getCategoriesTree();
    } on ServerException {
      rethrow;
    }
  }

  // ✅ NEW: Get flat list of all categories
  @override
  Future<List<AdminCategoryEntity>> getAllCategories() async {
    try {
      return await remoteDataSource.getAllCategories();
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> createCategory(Map<String, dynamic> data) async {
    try {
      await remoteDataSource.createCategory(data);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    try {
      await remoteDataSource.updateCategory(categoryId, data);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    try {
      await remoteDataSource.deleteCategory(categoryId);
    } on ServerException {
      rethrow;
    }
  }

  // ✅ NEW: Delete with product transfer
  @override
  Future<void> deleteCategoryWithTransfer(
    String categoryId,
    String targetCategoryId,
  ) async {
    try {
      await remoteDataSource.deleteCategoryWithTransfer(
        categoryId,
        targetCategoryId,
      );
    } on ServerException {
      rethrow;
    }
  }
}
