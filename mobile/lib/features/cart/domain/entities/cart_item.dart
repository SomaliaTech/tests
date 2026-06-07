import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;
  final bool inStock;
  final int maxStock;

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.inStock,
    required this.maxStock,
  });

  double get totalPrice => price * quantity; // This returns double

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
    bool? inStock,
    int? maxStock,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      inStock: inStock ?? this.inStock,
      maxStock: maxStock ?? this.maxStock,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    quantity,
    imageUrl,
    inStock,
    maxStock,
  ];
}

class Coupon extends Equatable {
  final String code;
  final double discount;
  final CouponType type;

  const Coupon({
    required this.code,
    required this.discount,
    required this.type,
  });

  double calculateDiscount(double subtotal) {
    if (type == CouponType.percentage) {
      return (subtotal * discount) / 100;
    } else {
      return discount;
    }
  }

  @override
  List<Object?> get props => [code, discount, type];
}

enum CouponType { percentage, fixed }
