import 'package:flutter/material.dart';
import 'product_card_skeleton.dart';

class ProductsGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductsGridSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 15,
        mainAxisExtent: 250,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const ProductCardSkeleton();
      },
    );
  }
}
