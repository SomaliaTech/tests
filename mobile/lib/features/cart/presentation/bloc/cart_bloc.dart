import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/cart/domain/entities/cart_item.dart';
import 'package:mobile/features/cart/domain/usecases/add_to_cart.dart';
import 'package:mobile/features/cart/domain/usecases/clear_cart.dart';
import 'package:mobile/features/cart/domain/usecases/get_cart_items.dart';
import 'package:mobile/features/cart/domain/usecases/remove_item.dart';
import 'package:mobile/features/cart/domain/usecases/update_quantity.dart';

import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final GetCartItems getCartItems;
  final AddToCart addToCart;
  final UpdateQuantity updateQuantity;
  final RemoveItem removeItem;
  final ClearCart clearCart;

  CartBloc({
    required this.getCartItems,
    required this.addToCart,
    required this.updateQuantity,
    required this.removeItem,
    required this.clearCart,
  }) : super(CartInitial()) {
    on<LoadCartEvent>(_onLoadCart);
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<RemoveItemEvent>(_onRemoveItem);
    on<ClearCartEvent>(_onClearCart);
    on<CartOrderCompletedEvent>(_onCartOrderCompleted);
  }

  Future<void> _onLoadCart(LoadCartEvent event, Emitter<CartState> emit) async {
    final result = await getCartItems();
    result.fold(
      (failure) => emit(CartError(failure.message)),
      (items) => _emitCartLoaded(items, emit),
    );
  }

  Future<void> _onAddToCart(
    AddToCartEvent event,
    Emitter<CartState> emit,
  ) async {
    final currentState = state;

    if (currentState is CartLoaded) {
      // Find if item already exists in cart
      final existingItemIndex = currentState.items.indexWhere(
        (item) => item.productVariantId == event.productVariantId,
      );

      if (existingItemIndex != -1) {
        // Optimistic update for existing item
        final updatedItems = List<CartItem>.from(currentState.items);
        final existingItem = updatedItems[existingItemIndex];
        updatedItems[existingItemIndex] = CartItem(
          id: existingItem.id, // Keep real ID
          productId: existingItem.productId,
          productVariantId: existingItem.productVariantId,
          name: existingItem.name,
          imageUrl: existingItem.imageUrl,
          price: existingItem.price,
          quantity: existingItem.quantity + event.quantity,
          maxStock: existingItem.maxStock,
          inStock: existingItem.inStock,
          color: existingItem.color,
          size: existingItem.size,
        );
        _emitCartLoaded(updatedItems, emit);
      } else {
        // Don't add temporary item, just show loading indicator
        emit(CartLoading());
      }
    } else {
      emit(CartLoading());
    }

    // Send to backend
    final result = await addToCart(event.productVariantId, event.quantity);

    result.fold(
      (failure) => emit(CartError(failure.message)),
      (_) => _onLoadCart(LoadCartEvent(), emit),
    );
  }

  Future<void> _onUpdateQuantity(
    UpdateQuantityEvent event,
    Emitter<CartState> emit,
  ) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      // OPTIMISTIC UPDATE: Update quantity locally
      final updatedItems = currentState.items.map((item) {
        if (item.id == event.itemId) {
          return CartItem(
            id: item.id,
            productId: item.productId,
            productVariantId: item.productVariantId,
            name: item.name,
            imageUrl: item.imageUrl,
            price: item.price,
            quantity: event.quantity,
            maxStock: item.maxStock,
            inStock: item.inStock,
            color: item.color,
            size: item.size,
          );
        }
        return item;
      }).toList();

      _emitCartLoaded(updatedItems, emit);

      // Send request to backend (don't reload on success)
      await updateQuantity(event.itemId, event.quantity);
    }
  }

  Future<void> _onRemoveItem(
    RemoveItemEvent event,
    Emitter<CartState> emit,
  ) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      // Remove from UI immediately
      final updatedItems = currentState.items
          .where((item) => item.id != event.itemId)
          .toList();
      _emitCartLoaded(updatedItems, emit);

      // Send to backend (don't wait for response to avoid race conditions)
      unawaited(removeItem(event.itemId));
    }
  }

  Future<void> _onClearCart(
    ClearCartEvent event,
    Emitter<CartState> emit,
  ) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      // OPTIMISTIC UPDATE: Clear cart locally
      _emitCartLoaded([], emit);

      // Send request to backend
      await clearCart();
    }
  }

  Future<void> _onCartOrderCompleted(
    CartOrderCompletedEvent event,
    Emitter<CartState> emit,
  ) async {
    // Clear cart locally
    _emitCartLoaded([], emit);
    // Clear remote cart
    await clearCart();
  }

  void _emitCartLoaded(List<CartItem> items, Emitter<CartState> emit) {
    const shippingFee = 5.0;
    const discount = 0.0;
    final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final total = subtotal + shippingFee - discount;
    final itemCount = items.fold(0, (sum, item) => sum + item.quantity);
    final isCheckoutEnabled =
        items.isNotEmpty && items.every((item) => item.inStock);

    emit(
      CartLoaded(
        items: items,
        subtotal: subtotal,
        shippingFee: shippingFee,
        discount: discount,
        total: total,
        itemCount: itemCount,
        isCheckoutEnabled: isCheckoutEnabled,
      ),
    );
  }
}
