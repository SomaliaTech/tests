import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';
import 'package:mobile/features/admin/domain/entities/color_entity.dart';
import 'package:mobile/features/admin/domain/entities/size_entity.dart';

abstract class AdminProductRepository {
  Future<List<AdminProductEntity>> getAllProducts();
  Future<AdminProductEntity> getProductById(String productId);
  Future<String> createProduct(Map<String, dynamic> productData);
  Future<void> updateProduct(String productId, Map<String, dynamic> updateData);
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
