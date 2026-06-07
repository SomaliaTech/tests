import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/orders_details/presentation/widgets/price_summary.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../widgets/bottom_checkout_bar.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/empty_cart_view.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.trash, color: Color(0xFFFF4757)),
            onPressed: () {
              _showClearCartDialog(context);
            },
          ),
        ],
      ),
      body: BlocListener<CartBloc, CartState>(
        listener: (context, state) {
          if (state is CartError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is CartSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF2ED573),
              ),
            );
          }
        },
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state is CartLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2ED573)),
              );
            }

            if (state is CartLoaded) {
              if (state.isCartEmpty) {
                return EmptyCartView(
                  onStartShopping: () => Navigator.pop(context),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          // Cart Items
                          ...state.items.map(
                            (item) => CartItemCard(
                              item: item,
                              onIncrement: () {
                                if (item.quantity < item.maxStock) {
                                  context.read<CartBloc>().add(
                                    CartUpdateQuantity(
                                      id: item.id,
                                      quantity: item.quantity + 1,
                                    ),
                                  );
                                }
                              },
                              onDecrement: () {
                                if (item.quantity > 1) {
                                  context.read<CartBloc>().add(
                                    CartUpdateQuantity(
                                      id: item.id,
                                      quantity: item.quantity - 1,
                                    ),
                                  );
                                }
                              },
                              onRemove: () {
                                _showRemoveItemDialog(context, item.id);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Coupon Section
                          const SizedBox(height: 20),

                          // Price Summary
                          PriceSummary(
                            subtotal: state.subtotal,
                            shippingFee: state.shippingFee,
                            discount: state.discount,
                            total: state.total,
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Checkout Bar
                  BottomCheckoutBar(
                    itemCount: state.itemCount,
                    total: state.total,
                    isEnabled: state.isCheckoutEnabled,
                    onCheckout: () {
                      context.read<CartBloc>().add(ProceedToCheckout());
                    },
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showRemoveItemDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: const Text(
            'Are you sure you want to remove this item from cart?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Use the original context, not dialogContext
                if (context.mounted) {
                  context.read<CartBloc>().add(CartRemoveItem(id));
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF4757),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text('Remove all items from cart?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Use the original context, not dialogContext
                if (context.mounted) {
                  context.read<CartBloc>().add(CartClearAll());
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF4757),
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
}
