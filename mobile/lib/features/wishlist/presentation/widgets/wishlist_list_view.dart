import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  toastification.show(
                    title: const Text('Added to Cart'),
                    description: Text('${item.name} added to cart'),
                    type: ToastificationType.success,
                    style: ToastificationStyle.fillColored,
                    autoCloseDuration: const Duration(seconds: 2),
                  );
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
