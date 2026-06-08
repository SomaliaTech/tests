import 'package:equatable/equatable.dart';
import 'package:mobile/features/wishlist/domain/entities/wishlist_item.dart';

abstract class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object?> get props => [];
}

class LoadWishlistEvent extends WishlistEvent {}

class AddToWishlistEvent extends WishlistEvent {
  final WishlistItem item;
  const AddToWishlistEvent(this.item);

  @override
  List<Object?> get props => [item];
}

class RemoveFromWishlistEvent extends WishlistEvent {
  final String itemId;
  const RemoveFromWishlistEvent(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class ClearWishlistEvent extends WishlistEvent {}

class CheckInWishlistEvent extends WishlistEvent {
  final String itemId;
  const CheckInWishlistEvent(this.itemId);

  @override
  List<Object?> get props => [itemId];
}
