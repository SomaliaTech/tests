import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/wishlist/domain/usecases/add_to_wishlist.dart';
import 'package:mobile/features/wishlist/domain/usecases/clear_wishlist.dart';
import 'package:mobile/features/wishlist/domain/usecases/get_wishlist_items.dart';
import 'package:mobile/features/wishlist/domain/usecases/is_in_wishlist.dart';
import 'package:mobile/features/wishlist/domain/usecases/remove_from_wishlist.dart';

import 'wishlist_event.dart';
import 'wishlist_state.dart';

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final GetWishlistItems getWishlistItems;
  final AddToWishlist addToWishlist;
  final RemoveFromWishlist removeFromWishlist;
  final ClearWishlist clearWishlist;
  final IsInWishlist isInWishlist;

  WishlistBloc({
    required this.getWishlistItems,
    required this.addToWishlist,
    required this.removeFromWishlist,
    required this.clearWishlist,
    required this.isInWishlist,
  }) : super(WishlistInitial()) {
    on<LoadWishlistEvent>(_onLoadWishlist);
    on<AddToWishlistEvent>(_onAddToWishlist);
    on<RemoveFromWishlistEvent>(_onRemoveFromWishlist);
    on<ClearWishlistEvent>(_onClearWishlist);
    on<CheckInWishlistEvent>(_onCheckInWishlist);
  }

  Future<void> _onLoadWishlist(
    LoadWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    emit(WishlistLoading());
    final result = await getWishlistItems();
    result.fold(
      (failure) => emit(WishlistError(failure.message)),
      (items) => emit(WishlistLoaded(items)),
    );
  }

  Future<void> _onAddToWishlist(
    AddToWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    final result = await addToWishlist(event.item);
    result.fold((failure) => emit(WishlistError(failure.message)), (_) {
      emit(WishlistItemAdded(event.item));
      add(LoadWishlistEvent()); // Reload to get updated list
    });
  }

  Future<void> _onRemoveFromWishlist(
    RemoveFromWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    final result = await removeFromWishlist(event.itemId);
    result.fold((failure) => emit(WishlistError(failure.message)), (_) {
      emit(WishlistItemRemoved(event.itemId));
      add(LoadWishlistEvent()); // Reload to get updated list
    });
  }

  Future<void> _onClearWishlist(
    ClearWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    final result = await clearWishlist();
    result.fold((failure) => emit(WishlistError(failure.message)), (_) {
      emit(WishlistCleared());
      add(LoadWishlistEvent()); // Reload to get empty list
    });
  }

  Future<void> _onCheckInWishlist(
    CheckInWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    final result = await isInWishlist(event.itemId);
    result.fold(
      (failure) => emit(WishlistError(failure.message)),
      (isIn) => emit(WishlistCheckResult(isIn)),
    );
  }
}
