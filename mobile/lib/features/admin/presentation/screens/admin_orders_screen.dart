// lib/features/admin/presentation/screens/admin_orders_screen.dart
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
  final SoundService _soundService = SoundService();
  Timer? _autoRefreshTimer;
  bool _showSearch = false;

  final List<Map<String, dynamic>> _statusFilters = [
    {'label': 'ALL', 'icon': Iconsax.box_1, 'color': Color(0xFF6B7280)},
    {'label': 'PENDING', 'icon': Iconsax.clock, 'color': Colors.orange},
    {'label': 'CONFIRMED', 'icon': Iconsax.verify, 'color': Colors.purple},
    {
      'label': 'PROCESSING',
      'icon': Iconsax.refresh_circle,
      'color': Colors.blue,
    },
    {'label': 'SHIPPED', 'icon': Iconsax.truck_fast, 'color': Colors.indigo},
    {
      'label': 'OUT_FOR_DELIVERY',
      'icon': Iconsax.car,
      'color': Color(0xFF9C27B0),
    },
    {
      'label': 'DELIVERED',
      'icon': Iconsax.tick_circle,
      'color': Color(0xFF2ED573),
    },
    {'label': 'CANCELLED', 'icon': Iconsax.close_circle, 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );
    _animationController.forward();

    _soundService.init();
    context.read<AdminBloc>().add(const FetchAllOrdersEvent());
    _setupWebSocketListeners();
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

    _newOrderSub = socketService.onNewOrder.listen((orderData) {
      if (!mounted) return;

      HapticFeedback.heavyImpact();
      _soundService.playMessageSound();

      context.read<AdminBloc>().add(FetchAllOrdersEvent(search: _searchQuery));

      final orderNumber = orderData['orderNumber'] ?? 'Unknown';
      final customerName = orderData['customerName'] ?? 'Customer';
      final totalAmount = orderData['totalAmount'] ?? '0';

      // ✅ Show stylish notification
      toastification.show(
        context: context,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.shopping_bag,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'New Order Received! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        description: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #$orderNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Iconsax.user, color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    customerName,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Iconsax.money, color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '\$$totalAmount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 6),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
        showProgressBar: true,
        padding: const EdgeInsets.all(16),
      );
    });

    _notificationSub = socketService.onNewNotification.listen((notification) {
      if (!mounted) return;

      final type = notification['type'] as String?;
      if (type == 'order' || type == 'payment') {
        context.read<AdminBloc>().add(
          FetchAllOrdersEvent(search: _searchQuery),
        );
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
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newOrderSub?.cancel();
    _notificationSub?.cancel();
    _autoRefreshTimer?.cancel();
    _animationController.dispose();
    _soundService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // App Bar
            _buildAppBar(),

            // ✅ Gap after App Bar
            SliverToBoxAdapter(
              child: Container(height: 8, color: const Color(0xFFF5F7FA)),
            ),

            // Stats Bar
            _buildStatsBar(),

            // ✅ Gap after Stats Bar
            SliverToBoxAdapter(
              child: Container(height: 8, color: const Color(0xFFF5F7FA)),
            ),

            // Search Toggle
            SliverToBoxAdapter(child: _buildSearchToggle()),

            // Search Bar (conditional)
            if (_showSearch) SliverToBoxAdapter(child: _buildSearchBar()),

            // ✅ Gap after Search
            SliverToBoxAdapter(
              child: Container(height: 4, color: const Color(0xFFF5F7FA)),
            ),

            // Status Filters
            _buildStatusFilters(),

            // ✅ Gap after Status Filters
            SliverToBoxAdapter(
              child: Container(height: 8, color: const Color(0xFFF5F7FA)),
            ),

            // Orders List
            _buildOrdersList(bottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        toastification.show(
          context: context,
          title: const Text('Coming Soon'),
          description: const Text('Manual order creation coming soon!'),
          type: ToastificationType.info,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 2),
        );
      },
      icon: const Icon(Iconsax.add, color: Colors.white),
      label: const Text(
        'New Order',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      backgroundColor: const Color(0xFF2ED573),
      elevation: 8,
      // shadowColor: const Color(0xFF2ED573).withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 0,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF8FAFC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          // Animated logo
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2ED573).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.shopping_cart,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Orders',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              Text(
                'Manage & track orders',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Refresh button
        IconButton(
          icon: const Icon(Iconsax.refresh, color: Color(0xFF1F2937)),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<AdminBloc>().add(
              FetchAllOrdersEvent(search: _searchQuery),
            );
          },
          tooltip: 'Refresh',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF3F4F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Order count badge
        BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            int orderCount = 0;
            int pendingCount = 0;
            if (state is AdminOrdersLoaded) {
              orderCount = state.orders.length;
              pendingCount = state.orders
                  .where((o) => o.status == 'PENDING')
                  .length;
            }
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2ED573).withOpacity(0.15),
                      const Color(0xFF1ABC9C).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2ED573).withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2ED573).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.box_1,
                      color: Color(0xFF2ED573),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$orderCount',
                      style: const TextStyle(
                        color: Color(0xFF2ED573),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 16,
                        color: const Color(0xFF2ED573).withOpacity(0.3),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    return SliverToBoxAdapter(
      child: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is! AdminOrdersLoaded) return const SizedBox.shrink();

          final orders = state.orders;
          final totalOrders = orders.length;
          final pendingOrders = orders
              .where((o) => o.status == 'PENDING')
              .length;
          final todayOrders = orders.where((o) {
            final orderDate = o.createdAt;
            final now = DateTime.now();
            return orderDate.year == now.year &&
                orderDate.month == now.month &&
                orderDate.day == now.day;
          }).length;
          final totalRevenue = orders
              .where((o) => o.status != 'CANCELLED')
              .fold<double>(
                0,
                (sum, o) =>
                    sum + (double.tryParse(o.totalAmount.toString()) ?? 0),
              );

          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated statistics cards
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      _buildStatCard(
                        'Today',
                        '$todayOrders',
                        Iconsax.calendar,
                        const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        'Pending',
                        '$pendingOrders',
                        Iconsax.clock,
                        Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        'Total',
                        '$totalOrders',
                        Iconsax.box_1,
                        const Color(0xFF2ED573),
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        'Revenue',
                        '\$${totalRevenue.toStringAsFixed(0)}',
                        Iconsax.money,
                        const Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchToggle() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _showSearch = !_showSearch);
                if (!_showSearch) {
                  _searchController.clear();
                  _onSearchChanged('');
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _showSearch
                      ? const Color(0xFF2ED573).withOpacity(0.1)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _showSearch
                        ? const Color(0xFF2ED573)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showSearch
                          ? Iconsax.search_normal
                          : Iconsax.search_normal,
                      color: _showSearch
                          ? const Color(0xFF2ED573)
                          : Colors.grey[400],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showSearch ? 'Search active' : 'Search orders...',
                      style: TextStyle(
                        color: _showSearch
                            ? const Color(0xFF2ED573)
                            : Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: Colors.white,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2ED573).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2ED573).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(
              Iconsax.search_normal,
              color: Color(0xFF2ED573),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
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
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.close_circle,
                    color: Color(0xFF9CA3AF),
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _statusFilters.map((filter) {
              final isSelected = _selectedStatus == filter['label'];
              final color = filter['color'] as Color;
              final icon = filter['icon'] as IconData;
              final label = filter['label'] as String;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _onStatusFilterChanged(label),
                  child: Container(
                    // ✅ Wrap in a Container for shadow (avoids animation issue)
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null, // ✅ null shadow when not selected (no animation)
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [color, color.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 14,
                            color: isSelected ? Colors.white : color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label.replaceAll('_', ' '),
                            style: TextStyle(
                              color: isSelected ? Colors.white : color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(double bottomPadding) {
    return SliverFillRemaining(
      child: BlocConsumer<AdminBloc, AdminState>(
        listenWhen: (prev, current) => current is AdminStatusUpdated,
        listener: (context, state) {
          if (state is AdminStatusUpdated) {
            _soundService.playMessageSound();
            toastification.show(
              context: context,
              title: const Text('Status Updated'),
              description: Text(state.message),
              type: ToastificationType.success,
              style: ToastificationStyle.fillColored,
              autoCloseDuration: const Duration(seconds: 2),
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
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 100),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemCount: filteredOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: _buildOrderCard(filteredOrders[index]),
                  );
                },
              ),
            );
          }

          if (state is AdminOrdersError) return _buildErrorState(state.message);

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    DateTime orderDate;
    if (order.createdAt != null) {
      orderDate = order.createdAt is String
          ? DateTime.parse(order.createdAt)
          : order.createdAt as DateTime;
    } else {
      orderDate = DateTime.now();
    }

    final timeAgo = _getTimeAgo(orderDate);
    final statusColor = _getStatusColor(order.status);
    final totalAmount = double.tryParse(order.totalAmount.toString()) ?? 0;

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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: const Color(0xFF2ED573).withOpacity(0.05),
            highlightColor: const Color(0xFF2ED573).withOpacity(0.03),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminOrderDetailsScreen(order: order),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Status indicator
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Order info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '#${order.orderNumber}',
                                    style: const TextStyle(
                                      color: Color(0xFF1F2937),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBadge(order.status, statusColor),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.clock,
                                  size: 12,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Amount
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ED573).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '\$${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Bottom Row
                  Row(
                    children: [
                      // Customer avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2ED573).withOpacity(0.2),
                              const Color(0xFF1ABC9C).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            (order.customerName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.customerName ?? 'Unknown',
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Items count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.box,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${order.itemsCount} items',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
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
        return const Color(0xFF9C27B0);
      case 'DELIVERED':
        return const Color(0xFF2ED573);
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2ED573).withOpacity(0.1),
                          const Color(0xFF1ABC9C).withOpacity(0.05),
                        ],
                      ),
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
                );
              },
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
            ),
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
