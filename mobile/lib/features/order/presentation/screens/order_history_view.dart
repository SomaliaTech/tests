import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/order/presentation/screens/order_details_screen.dart';
import 'package:mobile/features/tracking/presentation/screens/tracking_screen.dart';
import '../bloc/order_history_bloc.dart';
import '../bloc/order_history_event.dart';
import '../bloc/order_history_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/order_card.dart';

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
        centerTitle: false,
      ),
      // 🚨 FIXED: Removed the duplicate BlocProvider and LoadOrdersEvent()
      // It is already provided and loaded in OrderHistoryScreen!
      body: const _OrderHistoryBody(),
    );
  }
}

class _OrderHistoryBody extends StatelessWidget {
  const _OrderHistoryBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderHistoryBloc, OrderHistoryState>(
      builder: (context, state) {
        if (state is OrderHistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is OrderHistoryLoaded) {
          final orders = state.orders;
          if (orders.isEmpty) {
            return const EmptyState(message: 'No orders found');
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<OrderHistoryBloc>().add(RefreshOrdersEvent());
            },
            color: const Color(0xFF2ED573),
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderCard(
                  order: order,
                  onTrackPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackingScreen(orderId: order.id),
                      ),
                    );
                  },
                  onDetailsPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderDetailsScreen(orderId: order.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        } else if (state is OrderHistoryError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<OrderHistoryBloc>().add(LoadOrdersEvent());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ED573),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
