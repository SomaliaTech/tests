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
    emit(CartLoading());
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
    // 1. Save to local storage
    await addToCart(event.item);
    // 2. Reload local storage and emit
    add(LoadCartEvent());
  }

  Future<void> _onUpdateQuantity(
    UpdateQuantityEvent event,
    Emitter<CartState> emit,
  ) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      // 🚨 FIXED: Match by productVariantId instead of id
      final updatedItems = currentState.items.map((item) {
        if (item.productVariantId == event.itemId) {
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

      final result = await updateQuantity(event.itemId, event.quantity);

      result.fold(
        (failure) => emit(CartError(failure.message)),
        (_) => add(LoadCartEvent()),
      );
    }
  }

  Future<void> _onRemoveItem(
    RemoveItemEvent event,
    Emitter<CartState> emit,
  ) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      // 🚨 FIXED: Filter by productVariantId instead of id
      final updatedItems = currentState.items
          .where((item) => item.productVariantId != event.itemId)
          .toList();
      _emitCartLoaded(updatedItems, emit);

      final result = await removeItem(event.itemId);

      result.fold(
        (failure) => emit(CartError(failure.message)),
        (_) => add(LoadCartEvent()),
      );
    }
  }

  Future<void> _onClearCart(
    ClearCartEvent event,
    Emitter<CartState> emit,
  ) async {
    await clearCart();
    _emitCartLoaded([], emit);
  }

  Future<void> _onCartOrderCompleted(
    CartOrderCompletedEvent event,
    Emitter<CartState> emit,
  ) async {
    await clearCart(); // Clear local storage after successful checkout
    emit(const CartOrderSuccess('Order placed successfully!'));
  }

  void _emitCartLoaded(List<CartItem> items, Emitter<CartState> emit) {
    const shippingFee = 5.0;
    const discount = 0.0;
    final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final total = subtotal + shippingFee - discount;
    final itemCount = items.length; // Distinct items count for badge
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
