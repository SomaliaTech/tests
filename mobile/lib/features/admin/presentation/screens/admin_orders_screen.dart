import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/core/services/sound/sound_service.dart';
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

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'ALL';
  StreamSubscription? _newOrderSub;
  StreamSubscription? _notificationSub;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final SoundService _soundService = SoundService(); // ✅ Sound service
  Timer? _autoRefreshTimer; // ✅ Auto-refresh timer

  final List<String> _statusFilters = [
    'ALL',
    'PENDING',
    'CONFIRMED',
    'PROCESSING',
    'SHIPPED',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // ✅ Initialize sound service
    _soundService.init();

    // ✅ Load orders
    context.read<AdminBloc>().add(const FetchAllOrdersEvent());

    // ✅ Setup real-time listeners
    _setupWebSocketListeners();

    // ✅ Auto-refresh every 60 seconds
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        context.read<AdminBloc>().add(
          FetchAllOrdersEvent(search: _searchQuery),
        );
      }
    });
  }

  void _setupWebSocketListeners() {
    final socketService = sl<ChatSocketService>();

    // ✅ Listen for new orders
    _newOrderSub = socketService.onNewOrder.listen((orderData) {
      if (!mounted) return;

      HapticFeedback.mediumImpact();

      // ✅ Play notification sound
      _soundService.playMessageSound();

      // ✅ Refresh orders
      context.read<AdminBloc>().add(FetchAllOrdersEvent(search: _searchQuery));

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

    // ✅ Listen for all notifications (including order status changes)
    _notificationSub = socketService.onNewNotification.listen((notification) {
      if (!mounted) return;

      final type = notification['type'] as String?;
      if (type == 'order' || type == 'payment') {
        // ✅ Refresh orders on any order-related notification
        context.read<AdminBloc>().add(
          FetchAllOrdersEvent(search: _searchQuery),
        );

        // ✅ Play sound for admin
        _soundService.playMessageSound();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    context.read<AdminBloc>().add(FetchAllOrdersEvent(search: query));
  }

  void _onStatusFilterChanged(String status) {
    setState(() => _selectedStatus = status);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newOrderSub?.cancel();
    _notificationSub?.cancel();
    _autoRefreshTimer?.cancel(); // ✅ Cancel timer
    _animationController.dispose();
    _soundService.dispose(); // ✅ Dispose sound
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildStatusFilters()),
            _buildOrdersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.lightImpact();
        toastification.show(
          context: context,
          title: const Text('Coming Soon'),
          description: const Text('Create order feature is coming soon!'),
          type: ToastificationType.info,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 2),
        );
      },
      icon: const Icon(Iconsax.add, color: Colors.white),
      label: const Text(
        'New Order',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: const Color(0xFF2ED573),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2ED573).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Iconsax.shopping_cart,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Orders',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        // ✅ Refresh button
        IconButton(
          icon: const Icon(Iconsax.refresh, color: Color(0xFF1F2937)),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<AdminBloc>().add(
              FetchAllOrdersEvent(search: _searchQuery),
            );
          },
          tooltip: 'Refresh',
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: BlocBuilder<AdminBloc, AdminState>(
            builder: (context, state) {
              int orderCount = 0;
              if (state is AdminOrdersLoaded) {
                orderCount = state.orders.length;
              }
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ED573).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2ED573).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.box_1,
                      color: Color(0xFF2ED573),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$orderCount',
                      style: const TextStyle(
                        color: Color(0xFF2ED573),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(
              Iconsax.search_normal,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Color(0xFF1F2937)),
                decoration: const InputDecoration(
                  hintText: 'Search by order # or customer...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    Iconsax.close_circle,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: _statusFilters.map((status) {
            final isSelected = _selectedStatus == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _onStatusFilterChanged(status),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2ED573) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2ED573)
                          : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF2ED573,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return SliverFillRemaining(
      child: BlocConsumer<AdminBloc, AdminState>(
        listenWhen: (prev, current) => current is AdminStatusUpdated,
        listener: (context, state) {
          if (state is AdminStatusUpdated) {
            // ✅ Play sound on status update
            _soundService.playMessageSound();
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2ED573)),
                  SizedBox(height: 16),
                  Text(
                    'Loading orders...',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            );
          }

          if (state is AdminOrdersLoaded) {
            final filteredOrders = _selectedStatus == 'ALL'
                ? state.orders
                : state.orders
                      .where((order) => order.status == _selectedStatus)
                      .toList();

            if (filteredOrders.isEmpty) return _buildEmptyState();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminBloc>().add(
                  FetchAllOrdersEvent(search: _searchQuery),
                );
                await Future.delayed(const Duration(milliseconds: 800));
              },
              color: const Color(0xFF2ED573),
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).padding.bottom + 120,
                ),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemCount: filteredOrders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _buildOrderCard(context, filteredOrders[index]),
              ),
            );
          }

          if (state is AdminOrdersError) return _buildErrorState(state.message);

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    DateTime orderDate;
    if (order.createdAt != null) {
      if (order.createdAt is String) {
        orderDate = DateTime.parse(order.createdAt);
      } else if (order.createdAt is DateTime) {
        orderDate = order.createdAt;
      } else {
        orderDate = DateTime.now();
      }
    } else {
      orderDate = DateTime.now();
    }

    final timeAgo = _getTimeAgo(orderDate);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            order.status,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Iconsax.shopping_cart,
                          color: _getStatusColor(order.status),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${order.orderNumber}',
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Iconsax.user, color: Colors.grey[600], size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.customerName ?? 'Unknown',
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.box, color: Colors.grey[500], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${order.itemsCount} item${order.itemsCount > 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  '\$${double.tryParse(order.totalAmount.toString())?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    color: Color(0xFF2ED573),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
      case 'PROCESSING':
        return Colors.purple;
      case 'SHIPPED':
        return Colors.blue;
      case 'OUT_FOR_DELIVERY':
        return const Color(0xFF9C27B0); // ✅ Added
      case 'DELIVERED':
        return const Color(0xFF2ED573);
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2ED573).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty || _selectedStatus != 'ALL'
                    ? Iconsax.search_status
                    : Iconsax.shopping_cart,
                size: 64,
                color: const Color(0xFF2ED573),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty || _selectedStatus != 'ALL'
                  ? 'No orders found'
                  : 'No orders yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedStatus != 'ALL'
                  ? 'Try adjusting your search or filters'
                  : 'Orders will appear here when customers place them',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty || _selectedStatus != 'ALL') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedStatus = 'ALL';
                  });
                  context.read<AdminBloc>().add(const FetchAllOrdersEvent());
                },
                icon: const Icon(Iconsax.refresh),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ED573),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<AdminBloc>().add(
                FetchAllOrdersEvent(search: _searchQuery),
              ),
              icon: const Icon(Iconsax.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ED573),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}
