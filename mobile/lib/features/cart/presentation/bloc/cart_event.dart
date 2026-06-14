import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class LoadCartEvent extends CartEvent {}

class UpdateQuantityEvent extends CartEvent {
  final String itemId;
  final int quantity;
  const UpdateQuantityEvent(this.itemId, this.quantity);
  @override
  List<Object?> get props => [itemId, quantity];
}

class RemoveItemEvent extends CartEvent {
  final String itemId;
  const RemoveItemEvent(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class AddToCartEvent extends CartEvent {
  final String productVariantId;
  final int quantity;
  const AddToCartEvent({
    required this.productVariantId,
    required this.quantity,
  });
  @override
  List<Object?> get props => [productVariantId, quantity];
}

class ClearCartEvent extends CartEvent {}

class ProceedToCheckoutEvent extends CartEvent {}

class CartOrderCompletedEvent extends CartEvent {} // Add this
