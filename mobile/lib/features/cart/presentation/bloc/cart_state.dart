import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item.dart';

abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;
  final int itemCount;
  final bool isCheckoutEnabled;

  const CartLoaded({
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
    required this.itemCount,
    required this.isCheckoutEnabled,
  });

  bool get isCartEmpty => items.isEmpty;

  @override
  List<Object?> get props => [
    items,
    subtotal,
    shippingFee,
    discount,
    total,
    itemCount,
    isCheckoutEnabled,
  ];
}

// Add this state
class CartProceedToCheckout extends CartState {}

class CartSuccess extends CartState {
  final String message;
  const CartSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class CartError extends CartState {
  final String message;
  const CartError(this.message);
  @override
  List<Object?> get props => [message];
}

class CartOrderSuccess extends CartState {
  final String message;
  const CartOrderSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
