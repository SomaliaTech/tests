import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/wishlist/presentation/bloc/wishlist_state.dart';
import 'package:mobile/features/wishlist/presentation/widgets/wishlist_item_card.dart';
import 'package:toastification/toastification.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../bloc/wishlist_bloc.dart';
import '../bloc/wishlist_event.dart';

class WishlistListView extends StatelessWidget {
  const WishlistListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, cartState) {
        if (cartState is CartLoaded) {
          toastification.show(
            title: const Text('Added to Cart'),
            description: const Text('Item successfully added to your cart'),
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 2),
          );
        } else if (cartState is CartError) {
          toastification.show(
            title: const Text('Error'),
            description: Text(cartState.message),
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      },
      child: BlocBuilder<WishlistBloc, WishlistState>(
        builder: (context, state) {
          if (state is WishlistLoaded) {
            if (state.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.heart,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Your wishlist is empty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save your favorite items to buy them later',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Iconsax.trash,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  onDismissed: (direction) {
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
                  child: WishlistItemCard(
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
                      context.read<CartBloc>().add(
                        AddToCartEvent(
                          productVariantId: item.productVariantId,
                          quantity: 1,
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
