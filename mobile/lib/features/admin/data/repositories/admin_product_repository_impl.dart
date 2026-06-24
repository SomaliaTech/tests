import 'package:mobile/core/error/exceptions.dart';
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
    try {
      return await remoteDataSource.getAllProducts();
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<AdminProductEntity> getProductById(String productId) async {
    try {
      return await remoteDataSource.getProductById(productId);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<String> createProduct(Map<String, dynamic> productData) async {
    try {
      return await remoteDataSource.createProduct(productData);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await remoteDataSource.updateProduct(productId, updateData);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await remoteDataSource.deleteProduct(productId);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<AdminCategoryEntity>> getCategoriesTree() async {
    try {
      return await remoteDataSource.getCategoriesTree();
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<ColorEntity>> getColors() async {
    try {
      return await remoteDataSource.getColors();
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<SizeEntity>> getSizes() async {
    try {
      return await remoteDataSource.getSizes();
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> uploadProductImage(String productId, String base64Image) async {
    try {
      await remoteDataSource.uploadProductImage(productId, base64Image);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> addProductVariant(
    String productId,
    Map<String, dynamic> variantData,
  ) async {
    try {
      await remoteDataSource.addProductVariant(productId, variantData);
    } on ServerException {
      rethrow;
    }
  }
}
