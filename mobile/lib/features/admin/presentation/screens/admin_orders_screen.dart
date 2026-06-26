import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_state.dart';
import 'package:mobile/features/admin/presentation/screens/admin_order_details_screen.dart';
import 'package:toastification/toastification.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StreamSubscription? _newOrderSub;
  StreamSubscription? _notificationSub;

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const FetchAllOrdersEvent());
    _setupWebSocketListeners();
  }

  // ✅ NEW: Listen for real-time order notifications
  void _setupWebSocketListeners() {
    final socketService = sl<ChatSocketService>();

    // ✅ Listen for new orders
    _newOrderSub = socketService.onNewOrder.listen((orderData) {
      if (!mounted) return;

      // Refresh orders list
      context.read<AdminBloc>().add(FetchAllOrdersEvent(search: _searchQuery));

      // Show toast notification
      final orderNumber = orderData['orderNumber'] ?? 'Unknown';
      final customerName = orderData['customerName'] ?? 'Customer';
      final totalAmount = orderData['totalAmount'] ?? '0';

      toastification.show(
        context: context,
        title: const Text('🎉 New Order!'),
        description: Text(
          'Order #$orderNumber from $customerName - \$$totalAmount',
        ),
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 5),
        icon: const Icon(Iconsax.shopping_bag, color: Colors.white),
      );
    });

    // ✅ Listen for general notifications
    _notificationSub = socketService.onNewNotification.listen((notification) {
      if (!mounted) return;
      if (notification['type'] == 'order') {
        // Refresh orders when any order notification arrives
        context.read<AdminBloc>().add(
          FetchAllOrdersEvent(search: _searchQuery),
        );
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    context.read<AdminBloc>().add(FetchAllOrdersEvent(search: query));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newOrderSub?.cancel();
    _notificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.only(top: 60.0),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search by order # or customer name...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(
                      Iconsax.search_normal,
                      color: Colors.grey[400],
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Iconsax.close_circle,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            // Orders List
            Expanded(
              child: BlocConsumer<AdminBloc, AdminState>(
                listenWhen: (prev, current) => current is AdminStatusUpdated,
                listener: (context, state) {
                  if (state is AdminStatusUpdated) {
                    toastification.show(
                      context: context,
                      title: const Text('✅ Success'),
                      description: Text(state.message),
                      type: ToastificationType.success,
                      style: ToastificationStyle.fillColored,
                      autoCloseDuration: const Duration(seconds: 3),
                    );
                  }
                },
                buildWhen: (prev, current) =>
                    current is AdminOrdersLoading ||
                    current is AdminOrdersLoaded ||
                    current is AdminOrdersError,
                builder: (context, state) {
                  if (state is AdminOrdersLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }

                  if (state is AdminOrdersLoaded) {
                    final orders = state.orders;
                    if (orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.shopping_cart,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No orders found'
                                  : 'No orders yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: orders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _buildCompactOrderCard(context, order);
                      },
                    );
                  }

                  if (state is AdminOrdersError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.warning_2,
                            size: 64,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: TextStyle(color: Colors.red[400]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<AdminBloc>().add(
                                FetchAllOrdersEvent(search: _searchQuery),
                              );
                            },
                            icon: const Icon(Iconsax.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactOrderCard(BuildContext context, dynamic order) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminOrderDetailsScreen(order: order),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order # and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '#${order.orderNumber}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 12),
            // Customer Name
            Row(
              children: [
                Icon(Iconsax.user, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.customerName,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Items Count and Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.itemsCount} item${order.itemsCount > 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '\$${order.totalAmount}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'PENDING':
        bgColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange[700]!;
        break;
      case 'CONFIRMED':
      case 'PROCESSING':
        bgColor = Colors.purple.withValues(alpha: 0.15);
        textColor = Colors.purple[700]!;
        break;
      case 'SHIPPED':
        bgColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue[700]!;
        break;
      case 'DELIVERED':
        bgColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green[700]!;
        break;
      case 'CANCELLED':
        bgColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red[700]!;
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
