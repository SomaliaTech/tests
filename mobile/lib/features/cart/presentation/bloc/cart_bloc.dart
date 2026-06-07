import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/cart/domain/entities/cart_item.dart';
import 'package:mobile/features/cart/domain/usecases/clear_cart.dart';
import 'package:mobile/features/cart/domain/usecases/get_cart_items.dart';
import 'package:mobile/features/cart/domain/usecases/get_cart_summary.dart';
import 'package:mobile/features/cart/domain/usecases/remove_item.dart';
import 'package:mobile/features/cart/domain/usecases/update_quantity.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final GetCartItems getCartItems;
  final UpdateQuantity updateQuantity;
  final RemoveItem removeItem;
  final ClearCart clearCart;

  final GetCartSummary getCartSummary;

  Coupon? _appliedCoupon;

  CartBloc({
    required this.getCartItems,
    required this.updateQuantity,
    required this.removeItem,
    required this.clearCart,

    required this.getCartSummary,
  }) : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<CartUpdateQuantity>(_onUpdateQuantity);
    on<CartRemoveItem>(_onRemoveItem);
    on<CartClearAll>(_onClearCart);

    on<RemoveCoupon>(_onRemoveCoupon);
    on<ProceedToCheckout>(_onProceedToCheckout);
  }

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    emit(CartLoading());

    final result = await getCartItems();
    result.fold(
      (failure) => emit(CartError(failure.message)),
      (items) => _emitCartLoaded(items, emit),
    );
  }

  Future<void> _onUpdateQuantity(
    CartUpdateQuantity event,
    Emitter<CartState> emit,
  ) async {
    final result = await updateQuantity(event.id, event.quantity);
    result.fold(
      (failure) => emit(CartError(failure.message)),
      (_) => add(LoadCart()),
    );
  }

  Future<void> _onRemoveItem(
    CartRemoveItem event,
    Emitter<CartState> emit,
  ) async {
    final result = await removeItem(event.id);
    result.fold(
      (failure) => emit(CartError(failure.message)),
      (_) => add(LoadCart()),
    );
  }

  Future<void> _onClearCart(CartClearAll event, Emitter<CartState> emit) async {
    final result = await clearCart();
    result.fold(
      (failure) => emit(CartError(failure.message)),
      (_) => add(LoadCart()),
    );
  }

  void _onRemoveCoupon(RemoveCoupon event, Emitter<CartState> emit) {
    _appliedCoupon = null;
    add(LoadCart());
    emit(CartSuccess('Coupon removed'));
  }

  void _onProceedToCheckout(ProceedToCheckout event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final cartState = state as CartLoaded;
      if (cartState.isCheckoutEnabled) {
        emit(CartSuccess('Proceeding to checkout...'));
      } else if (cartState.isCartEmpty) {
        emit(CartError('Your cart is empty'));
      } else if (cartState.hasOutOfStockItems) {
        emit(CartError('Some items are out of stock'));
      }
    }
  }

  void _emitCartLoaded(List<CartItem> items, Emitter<CartState> emit) {
    final summary = getCartSummary(items, _appliedCoupon);
    emit(
      CartLoaded(
        items: items,
        appliedCoupon: _appliedCoupon,
        subtotal: summary.subtotal,
        shippingFee: summary.shippingFee,
        discount: summary.discount,
        total: summary.total,
        itemCount: summary.itemCount,
      ),
    );
  }
}
