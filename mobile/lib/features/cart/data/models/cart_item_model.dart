import '../../domain/entities/cart_item.dart';

class CartItemModel {
  const CartItemModel._();

  static CartItem fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      productId: json['productId'] as String? ?? '',
      productVariantId:
          json['productVariantId'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      maxStock: json['maxStock'] as int? ?? 999,
      inStock: json['inStock'] as bool? ?? true,
      color: json['color'] as String?,
      size: json['size'] as String?,
    );
  }

  static Map<String, dynamic> toJson(CartItem item) {
    return {
      'id': item.id,
      'productId': item.productId,
      'productVariantId': item.productVariantId,
      'name': item.name,
      'imageUrl': item.imageUrl,
      'price': item.price,
      'quantity': item.quantity,
      'maxStock': item.maxStock,
      'inStock': item.inStock,
      'color': item.color,
      'size': item.size,
    };
  }
}
