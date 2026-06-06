import 'package:flutter/material.dart';
import 'package:mobile/features/order_history/presentation/widgets/empty_state.dart';
import 'package:mobile/features/order_history/presentation/widgets/order_card.dart';
import 'package:mobile/features/order_history/presentation/widgets/tab_button.dart';
import 'package:mobile/features/order_history/presentation/providers/order_history_provider.dart';
import 'package:mobile/features/orders_details/presentation/screens/order_details_screen.dart';
import 'package:mobile/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

class OrderHistoryView extends StatelessWidget {
  const OrderHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Consumer<OrderHistoryProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TabButton(
                        isActive: provider.currentTab == OrderTab.products,
                        title: 'PRODUCTS',
                        onTap: () => provider.setTab(OrderTab.products),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TabButton(
                        isActive: provider.currentTab == OrderTab.internets,
                        title: 'INTERNETS',
                        onTap: () => provider.setTab(OrderTab.internets),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: Consumer<OrderHistoryProvider>(
        builder: (context, provider, child) {
          final orders = provider.currentOrders;

          if (orders.isEmpty) {
            return const EmptyState(message: 'No orders found');
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshOrders(),
            color: const Color(0xFF2ED573),
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderCard(
                  order: order,
                  onTrackPressed: () {
                    provider.trackOrder(order.id, order.trackingNumber);
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(
                    //     content: Text(
                    //       'Tracking order: ${order.trackingNumber}',
                    //     ),
                    //     duration: const Duration(seconds: 2),
                    //   ),
                    // );
                    // Navigate to tracking screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TrackingScreen(orderId: 'ORD-2024-001'),
                      ),
                    );
                  },
                  onDetailsPressed: () {
                    provider.viewOrderDetails(order.id);
                    // Navigate to order details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const OrderDetailsScreen(orderId: 'ORD-2024-001'),
                      ),
                    );
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(
                    //     content: Text('Viewing details for ${order.id}'),
                    //     duration: const Duration(seconds: 2),
                    //   ),
                    // );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
