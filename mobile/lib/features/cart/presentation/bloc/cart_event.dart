import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class LoadCartEvent extends CartEvent {}

// 🚨 CHANGED: Now accepts a full CartItem object
class AddToCartEvent extends CartEvent {
  final CartItem item;
  const AddToCartEvent(this.item);
  @override
  List<Object?> get props => [item];
}

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

class ClearCartEvent extends CartEvent {}

class CartOrderCompletedEvent extends CartEvent {}
