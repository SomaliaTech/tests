import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_event.dart';
import 'package:toastification/toastification.dart';
import '../bloc/wishlist_bloc.dart';
import '../bloc/wishlist_event.dart';
import '../bloc/wishlist_state.dart';
import 'wishlist_item_card.dart';

class WishlistListView extends StatelessWidget {
  const WishlistListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistBloc, WishlistState>(
      builder: (context, state) {
        if (state is WishlistLoaded) {
          if (state.items.isEmpty) {
            return const Center(child: Text('No items in wishlist'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 16),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return WishlistItemCard(
                item: item,
                onRemove: () {
                  context.read<WishlistBloc>().add(
                    RemoveFromWishlistEvent(item.id),
                  );
                  toastification.show(
                    title: const Text('Removed'),
                    description: Text('${item.name} removed from wishlist'),
                    type: ToastificationType.success,
                    style: ToastificationStyle.fillColored,
                    autoCloseDuration: const Duration(seconds: 2),
                  );
                },
                onAddToCart: () {
                  print('🛒 Wishlist: Add to cart pressed for ${item.name}');
                  print('   Product Variant ID: ${item.productVariantId}');

                  // Check if CartBloc is available
                  try {
                    final cartBloc = context.read<CartBloc>();
                    print('✅ CartBloc is available: ${cartBloc != null}');

                    cartBloc.add(
                      AddToCartEvent(
                        productVariantId: item.productVariantId,
                        quantity: 1,
                      ),
                    );
                    print('✅ AddToCartEvent dispatched');

                    toastification.show(
                      title: const Text('Adding to Cart'),
                      description: Text('Adding ${item.name}...'),
                      type: ToastificationType.info,
                      autoCloseDuration: const Duration(seconds: 1),
                    );
                  } catch (e) {
                    print('❌ Error: CartBloc not found - $e');
                    toastification.show(
                      title: const Text('Error'),
                      description: Text('Cart service not available'),
                      type: ToastificationType.error,
                      autoCloseDuration: const Duration(seconds: 2),
                    );
                  }
                },
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
