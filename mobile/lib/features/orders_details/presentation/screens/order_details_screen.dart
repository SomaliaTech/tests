import 'package:flutter/material.dart';
import 'package:mobile/features/orders_details/presentation/screens/order_details_view.dart';
import 'package:mobile/features/orders_details/presentation/providers/order_details_provider.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return OrderDetailsView(orderId: orderId);
  }
}
