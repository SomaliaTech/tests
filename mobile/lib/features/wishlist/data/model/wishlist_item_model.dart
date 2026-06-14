import '../../domain/entities/wishlist_item.dart';

class WishlistItemModel extends WishlistItem {
  const WishlistItemModel({
    required super.id,
    required super.name,
    required super.price,
    required super.imageUrl,
    super.brand,
    super.rating,
    required super.categoryId,
    required super.productVariantId, // Add this
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      brand: json['brand'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      categoryId: json['categoryId'] as String,
      productVariantId:
          json['productVariantId'] as String? ?? json['id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'brand': brand,
      'rating': rating,
      'categoryId': categoryId,
      'productVariantId': productVariantId,
    };
  }
}
