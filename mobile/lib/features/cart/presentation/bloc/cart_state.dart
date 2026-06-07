import 'package:equatable/equatable.dart';
import 'package:mobile/features/cart/domain/entities/cart_item.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;
  final Coupon? appliedCoupon;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;
  final int itemCount;

  const CartLoaded({
    required this.items,
    this.appliedCoupon,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
    required this.itemCount,
  });

  bool get isCartEmpty => items.isEmpty;
  bool get hasOutOfStockItems => items.any((item) => !item.inStock);
  bool get isCheckoutEnabled => !isCartEmpty && !hasOutOfStockItems;

  @override
  List<Object?> get props => [
    items,
    appliedCoupon,
    subtotal,
    shippingFee,
    discount,
    total,
    itemCount,
  ];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

class CartSuccess extends CartState {
  final String message;

  const CartSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
