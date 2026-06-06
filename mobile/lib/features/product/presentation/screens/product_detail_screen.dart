import 'package:flutter/material.dart';
import 'product_detail_view.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  // 1. Change this to a static method that takes a productId parameter
  static Route route(String id) {
    return MaterialPageRoute(
      builder: (context) => ProductDetailScreen(productId: id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProductDetailView(productId: productId);
  }
}
