import 'package:flutter/material.dart';
import 'package:mobile/features/wishlist/presentation/provider/wishlist_provider.dart';
import 'package:provider/provider.dart';
import 'wishlist_item_card.dart';

class WishlistListView extends StatelessWidget {
  const WishlistListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: provider.items.length,
          itemBuilder: (context, index) {
            final item = provider.items[index];
            return WishlistItemCard(
              item: item,
              onRemove: () {
                provider.removeFromWishlist(item.id);

                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text('${item.name} removed from wishlist'),
                //     backgroundColor: Colors.grey[800],
                //     duration: const Duration(
                //       seconds: 2,
                //     ), // 👈 This makes it disappear after 5 seconds
                //     action: SnackBarAction(
                //       label: 'Undo',
                //       textColor: const Color(0xFF2ED573),
                //       onPressed: () {
                //         provider.addToWishlist(item);
                //       },
                //     ),
                //   ),
                // );
              },
              onAddToCart: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} added to cart'),
                    backgroundColor: const Color(0xFF2ED573),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
