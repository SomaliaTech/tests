import 'package:flutter/material.dart';
import 'package:mobile/features/order_history/presentation/providers/order_history_provider.dart';
import 'package:provider/provider.dart';
import 'order_history_view.dart';

class OrderHistoryScreen extends StatelessWidget {
  static Route route() {
    return MaterialPageRoute(builder: (context) => OrderHistoryScreen());
  }

  const OrderHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderHistoryProvider(),
      child: const OrderHistoryView(),
    );
  }
}
