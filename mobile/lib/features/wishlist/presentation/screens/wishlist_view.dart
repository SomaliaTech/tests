import 'package:flutter/material.dart';
import 'package:mobile/features/wishlist/presentation/widgets/empty_wishlist_view.dart';
import 'package:mobile/features/wishlist/presentation/widgets/wishlist_app_bar.dart';
import 'package:mobile/features/wishlist/presentation/widgets/wishlist_list_view.dart';
import 'package:mobile/features/wishlist/presentation/provider/wishlist_provider.dart';
import 'package:provider/provider.dart';

class WishlistView extends StatelessWidget {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const WishlistAppBar(),
      body: Consumer<WishlistProvider>(
        builder: (context, provider, child) {
          if (provider.isWishlistEmpty) {
            return const EmptyWishlistView();
          }
          return const WishlistListView();
        },
      ),
    );
  }
}
