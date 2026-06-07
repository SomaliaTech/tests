import '../../domain/entities/cart_item.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.id,
    required super.name,
    required super.price,
    required super.quantity,
    required super.imageUrl,
    required super.inStock,
    required super.maxStock,
  });

  factory CartItemModel.fromEntity(CartItem entity) {
    return CartItemModel(
      id: entity.id,
      name: entity.name,
      price: entity.price,
      quantity: entity.quantity,
      imageUrl: entity.imageUrl,
      inStock: entity.inStock,
      maxStock: entity.maxStock,
    );
  }

  CartItem toEntity() {
    return CartItem(
      id: id,
      name: name,
      price: price,
      quantity: quantity,
      imageUrl: imageUrl,
      inStock: inStock,
      maxStock: maxStock,
    );
  }
}
