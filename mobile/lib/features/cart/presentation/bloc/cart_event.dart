import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {}

// Renamed to CartUpdateQuantity
class CartUpdateQuantity extends CartEvent {
  final String id;
  final int quantity;

  const CartUpdateQuantity({required this.id, required this.quantity});

  @override
  List<Object?> get props => [id, quantity];
}

// Renamed to CartRemoveItem
class CartRemoveItem extends CartEvent {
  final String id;

  const CartRemoveItem(this.id);

  @override
  List<Object?> get props => [id];
}

// Renamed to CartClearAll
class CartClearAll extends CartEvent {}

class ApplyCouponCode extends CartEvent {
  final String code;

  const ApplyCouponCode(this.code);

  @override
  List<Object?> get props => [code];
}

class RemoveCoupon extends CartEvent {}

class ProceedToCheckout extends CartEvent {}
