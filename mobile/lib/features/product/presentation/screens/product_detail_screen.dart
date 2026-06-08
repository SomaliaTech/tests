import 'package:flutter/material.dart';
import 'package:mobile/features/product/presentation/screens/product_detail_view.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

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
