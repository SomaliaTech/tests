import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class EmptyWishlistView extends StatelessWidget {
  const EmptyWishlistView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/empty_wishlist.svg',
              height: 220,
              placeholderBuilder: (BuildContext context) => const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'My Wishlist is Empty!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please choose a heart product to  start saving\nyour favorite items.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
