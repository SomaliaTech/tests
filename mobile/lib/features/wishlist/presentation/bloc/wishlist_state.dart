import 'package:equatable/equatable.dart';
import 'package:mobile/features/wishlist/domain/entities/wishlist_item.dart';

abstract class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<WishlistItem> items;
  const WishlistLoaded(this.items);

  bool get isWishlistEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items];
}

class WishlistItemAdded extends WishlistState {
  final WishlistItem item;
  const WishlistItemAdded(this.item);

  @override
  List<Object?> get props => [item];
}

class WishlistItemRemoved extends WishlistState {
  final String itemId;
  const WishlistItemRemoved(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class WishlistCleared extends WishlistState {}

class WishlistCheckResult extends WishlistState {
  final bool isInWishlist;
  const WishlistCheckResult(this.isInWishlist);

  @override
  List<Object?> get props => [isInWishlist];
}

class WishlistError extends WishlistState {
  final String message;
  const WishlistError(this.message);

  @override
  List<Object?> get props => [message];
}
