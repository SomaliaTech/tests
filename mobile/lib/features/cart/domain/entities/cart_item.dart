import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String id;
  final String productId;
  final String productVariantId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final int maxStock;
  final bool inStock;
  final String? color;
  final String? size;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productVariantId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.maxStock,
    required this.inStock,
    this.color,
    this.size,
  });

  double get totalPrice => price * quantity;

  bool get canIncrease => quantity < maxStock && inStock;
  bool get canDecrease => quantity > 1;

  @override
  List<Object?> get props => [
    id,
    productId,
    productVariantId,
    name,
    imageUrl,
    price,
    quantity,
    maxStock,
    inStock,
    color,
    size,
  ];
}
