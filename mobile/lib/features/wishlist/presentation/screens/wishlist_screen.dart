import 'package:flutter/material.dart';
import 'package:mobile/features/wishlist/presentation/screens/wishlist_view.dart';

import 'package:mobile/features/wishlist/presentation/provider/wishlist_provider.dart';
import 'package:provider/provider.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WishlistProvider(),
      child: const WishlistView(),
    );
  }
}
