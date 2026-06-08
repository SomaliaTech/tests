import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.description,
    required super.price,
    required super.stock,
    required super.isActive,
    required super.categoryId,
    super.categoryName,
    super.brand,
    required super.imageUrls,
    required super.variants,
    required super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Use the entity's fromJson method
    final product = Product.fromJson(json);
    return ProductModel(
      id: product.id,
      name: product.name,
      slug: product.slug,
      description: product.description,
      price: product.price,
      stock: product.stock,
      isActive: product.isActive,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      brand: product.brand,
      imageUrls: product.imageUrls,
      variants: product.variants,
      createdAt: product.createdAt,
    );
  }
}
