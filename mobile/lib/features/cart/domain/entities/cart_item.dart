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

  // ✅ FIXED: More lenient check - allow increase if stock > 0 or maxStock is very high (999)
  bool get canIncrease {
    // If maxStock is 999 (default from wishlist), always allow increase
    if (maxStock >= 999) return true;
    // Otherwise check actual stock
    return inStock && quantity < maxStock;
  }

  bool get canDecrease => quantity > 1;

  CartItem copyWith({
    String? id,
    String? productId,
    String? productVariantId,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
    int? maxStock,
    bool? inStock,
    String? color,
    String? size,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productVariantId: productVariantId ?? this.productVariantId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      maxStock: maxStock ?? this.maxStock,
      inStock: inStock ?? this.inStock,
      color: color ?? this.color,
      size: size ?? this.size,
    );
  }

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
