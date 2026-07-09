import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/domain/entities/analytics_entities.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_state.dart';
import 'package:mobile/features/admin/presentation/bloc/analytics/analytics_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/analytics/analytics_event.dart';
import 'package:mobile/features/admin/presentation/bloc/analytics/analytics_state.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_event.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_state.dart';
import 'package:mobile/features/admin/presentation/screens/admin_categories_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_colors_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_faq_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_markets_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_sizes_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_revenue_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_main_navigation_screen.dart';
import 'package:mobile/features/admin/presentation/widgets/dashboard_widgets.dart';
import 'package:mobile/features/admin/presentation/widgets/skeleton_widgets.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:toastification/toastification.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ValueNotifier<String> _periodNotifier = ValueNotifier('week');
  StreamSubscription? _dashboardSubscription;
  StreamSubscription? _notificationSub;
  StreamSubscription? _newOrderSub;

  int _cachedUnreadCount = 0;
  bool _hasLoadedOnce = false;
  bool _isCheckingAdmin = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final storageService = GetIt.instance<StorageService>();
      final isAdmin = await storageService.getIsAdmin();
      final isSuperAdmin = await storageService.getIsSuperAdmin();

      if (!mounted) return;

      if (!isAdmin && !isSuperAdmin) {
        _redirectToHome('You do not have admin access');
        return;
      }

      setState(() {
        _isAdmin = true;
        _isCheckingAdmin = false;
      });

      _loadDashboardData();
    } catch (e) {
      _redirectToHome('Failed to verify admin access');
    }
  }

  void _loadDashboardData() {
    context.read<DashboardBloc>().add(
      const LoadDashboardDataEvent(period: 'week'),
    );
    context.read<AdminBloc>().add(FetchAllOrdersEvent());
    context.read<AnalyticsBloc>().add(const LoadAnalyticsEvent(period: 'week'));

    _dashboardSubscription = context.read<DashboardBloc>().stream.listen((
      state,
    ) {
      if (mounted && state is DashboardLoaded) {
        _periodNotifier.value = state.period;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
      _setupRealtimeNotifications();
    });
  }

  void _redirectToHome(String message) {
    toastification.show(
      context: context,
      title: const Text('Access Changed'),
      description: Text(message),
      type: ToastificationType.info,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
      icon: const Icon(Iconsax.info_circle, color: Colors.white),
    );

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  void _loadNotifications() {
    if (mounted) {
      context.read<NotificationsBloc>().add(LoadNotifications());
    }
  }

  void _setupRealtimeNotifications() {
    try {
      final socketService = GetIt.instance<ChatSocketService>();

      _notificationSub = socketService.onNewNotification.listen((data) {
        if (mounted) {
          if (data['type'] == 'order') {
            _showOrderNotification(data);
          }

          setState(() {
            _cachedUnreadCount++;
            _hasLoadedOnce = true;
          });
          context.read<NotificationsBloc>().add(LoadNotifications());
        }
      });

      _newOrderSub = socketService.onNewOrder.listen((orderData) {
        if (mounted) {
          _showNewOrderToast(orderData);
          context.read<AdminBloc>().add(FetchAllOrdersEvent());
          context.read<DashboardBloc>().add(
            LoadDashboardDataEvent(period: _periodNotifier.value),
          );
          context.read<AnalyticsBloc>().add(
            LoadAnalyticsEvent(period: _periodNotifier.value),
          );
        }
      });
    } catch (e) {
      debugPrint('Socket service not available: $e');
    }
  }

  void _showOrderNotification(Map<String, dynamic> notification) {
    toastification.show(
      context: context,
      title: Text(notification['title'] ?? 'New Order'),
      description: Text(notification['message'] ?? ''),
      type: ToastificationType.info,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 4),
      icon: const Icon(Iconsax.shopping_cart, color: Colors.white),
    );
  }

  void _showNewOrderToast(Map<String, dynamic> orderData) {
    final orderNumber = orderData['orderNumber'] ?? 'Unknown';
    final customerName = orderData['customerName'] ?? 'Customer';
    final totalAmount = orderData['totalAmount'] ?? '0';

    toastification.show(
      context: context,
      title: const Text('🎉 New Order Received!'),
      description: Text(
        'Order #$orderNumber from $customerName - \$$totalAmount',
      ),
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 5),
      icon: const Icon(Iconsax.shopping_bag, color: Colors.white),
    );
  }

  @override
  void dispose() {
    _dashboardSubscription?.cancel();
    _notificationSub?.cancel();
    _newOrderSub?.cancel();
    _periodNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAdmin || !_isAdmin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocListener<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardError) {
            final message = state.message.toLowerCase();
            if (message.contains('403') ||
                message.contains('forbidden') ||
                message.contains('administrators') ||
                message.contains('admin access') ||
                message.contains('unauthorized')) {
              _redirectToHome('Your admin access has been revoked');
            }
          }
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0), // ✅ Reduced from 16.0
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(context),
                    const SizedBox(height: 16), // ✅ Reduced from 20
                    _buildStatsSection(context),
                    const SizedBox(height: 16), // ✅ Reduced from 24
                    _buildChartsSection(context),
                    const SizedBox(height: 16), // ✅ Reduced from 24
                    _buildAnalyticsSection(context),
                    const SizedBox(height: 16), // ✅ Reduced from 24
                    _buildSectionTitle('Quick Management'),
                    const SizedBox(height: 8), // ✅ Reduced from 12
                    _buildQuickActions(context),
                    const SizedBox(height: 16), // ✅ Reduced from 24
                    _buildSectionTitle('Recent Orders'),
                    const SizedBox(height: 8), // ✅ Reduced from 12
                    _buildRecentOrders(context),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
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
              child: Icon(Iconsax.back_square, color: Colors.white),
            ),
          ),

          SizedBox(width: 12),
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
            child: const Icon(Iconsax.chart_21, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Dashboard',
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
        _AdminNotificationIcon(
          cachedCount: _cachedUnreadCount,
          hasLoadedOnce: _hasLoadedOnce,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    final periods = ['day', 'week', 'month', 'year'];

    return ValueListenableBuilder<String>(
      valueListenable: _periodNotifier,
      builder: (context, currentPeriod, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: periods.map((period) {
              final isSelected = period == currentPeriod;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (period != currentPeriod) {
                      _periodNotifier.value = period;
                      context.read<DashboardBloc>().add(
                        ChangePeriodEvent(period: period),
                      );
                      context.read<AnalyticsBloc>().add(
                        ChangeAnalyticsPeriodEvent(period),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2ED573)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        period.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ✅ ADDED: Stats Section (was missing from class)
  // ✅ FIXED: Stats Section with reduced gaps
  Widget _buildStatsSection(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const StatsSkeleton();
        }

        if (state is DashboardLoaded) {
          final hasNoData =
              state.stats.totalUsers == 0 &&
              state.stats.totalOrders == 0 &&
              state.stats.totalRevenue == 0;

          if (hasNoData) {
            return _buildEmptyStatsCard();
          }

          // ✅ Use Row/Column with Expanded for tighter spacing
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DashboardStatCard(
                      title: 'Total Users',
                      value: state.stats.totalUsers.toString(),
                      trend: state.stats.userGrowth,
                      icon: Iconsax.user,
                      color: Colors.blueAccent,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminUsersScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10), // ✅ Reduced from 16 to 10
                  Expanded(
                    child: DashboardStatCard(
                      title: 'Total Orders',
                      value: state.stats.totalOrders.toString(),
                      trend: state.stats.orderGrowth,
                      icon: Iconsax.shopping_cart,
                      color: Colors.orangeAccent,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminMainNavigationScreen(
                                  initialIndex: 2,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10), // ✅ Reduced from 16 to 10
              Row(
                children: [
                  Expanded(
                    child: DashboardStatCard(
                      title: 'Revenue',
                      value: '\$${state.stats.totalRevenue.toStringAsFixed(0)}',
                      trend: state.stats.revenueGrowth,
                      icon: Iconsax.money_tick,
                      color: AppTheme.primaryColor,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminRevenueScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10), // ✅ Reduced from 16 to 10
                  Expanded(
                    child: DashboardStatCard(
                      title: 'New Users',
                      value: state.stats.newUsers.toString(),
                      trend: state.stats.newUserGrowth,
                      icon: Iconsax.user_add,
                      color: Colors.purpleAccent,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        if (state is DashboardError) {
          final message = state.message.toLowerCase();
          if (message.contains('403') ||
              message.contains('forbidden') ||
              message.contains('administrators') ||
              message.contains('admin access')) {
            return const SizedBox.shrink();
          }

          return _buildErrorCard(state.message, () {
            context.read<DashboardBloc>().add(
              const LoadDashboardDataEvent(period: 'week'),
            );
          });
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyStatsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2ED573).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.chart_21,
              size: 48,
              color: const Color(0xFF2ED573).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Data Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Statistics will appear here once users start using the platform.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Column(
            children: [
              LineChartSkeleton(),
              SizedBox(height: 20),
              BarChartSkeleton(),
            ],
          );
        }

        if (state is DashboardLoaded) {
          return Column(
            children: [
              DashboardLineChart(
                title: 'User Growth',
                data: state.usersChartData,
              ),
              const SizedBox(height: 20),
              DashboardLineChart(
                title: 'Revenue Trend',
                data: state.revenueChartData,
              ),
            ],
          );
        }

        if (state is DashboardError) {
          final message = state.message.toLowerCase();
          if (message.contains('403') ||
              message.contains('forbidden') ||
              message.contains('administrators')) {
            return const SizedBox.shrink();
          }

          return _buildErrorCard('Failed to load charts', () {
            context.read<DashboardBloc>().add(
              const LoadDashboardDataEvent(period: 'week'),
            );
          });
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAnalyticsSection(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading) {
          return const Column(
            children: [
              _AnalyticsCardSkeleton(),
              SizedBox(height: 16),
              _AnalyticsCardSkeleton(),
              SizedBox(height: 16),
              _AnalyticsCardSkeleton(),
            ],
          );
        }

        if (state is AnalyticsLoaded) {
          return Column(
            children: [
              const SizedBox(height: 12),
              _buildTopProductsCard(state.data.topProducts),
              const SizedBox(height: 16),
              _buildRevenueByCategoryCard(state.data.revenueByCategory),
              const SizedBox(height: 16),
              _buildOrderStatusCard(state.data.orderStatusDistribution),
              const SizedBox(height: 16),
              _buildLowStockCard(state.data.lowStockProducts),
              const SizedBox(height: 16),
              _buildRecentSignupsCard(state.data.recentSignups),
            ],
          );
        }

        if (state is AnalyticsError) {
          return _buildErrorCard(state.message, () {
            context.read<AnalyticsBloc>().add(
              const LoadAnalyticsEvent(period: 'week'),
            );
          });
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTopProductsCard(List<TopProductEntity> products) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.star_1,
                  color: Colors.orange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Top Selling Products',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No sales data yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return _buildTopProductItem(index + 1, product);
            }),
        ],
      ),
    );
  }

  Widget _buildTopProductItem(int rank, TopProductEntity product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: rank == 1
                  ? const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    )
                  : rank == 2
                  ? const LinearGradient(
                      colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
                    )
                  : rank == 3
                  ? const LinearGradient(
                      colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
                    )
                  : null,
              color: rank > 3 ? Colors.grey[200] : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rank <= 3 ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product Image
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Iconsax.image,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  )
                : const Icon(Iconsax.image, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.totalSold} sold • ${product.orderCount} orders',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          // Revenue
          Text(
            '\$${product.totalRevenue.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2ED573),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByCategoryCard(List<CategoryRevenueEntity> categories) {
    // ✅ Calculate total revenue for percentage
    final totalRevenue = categories.fold<double>(
      0,
      (sum, category) => sum + category.totalRevenue,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.category,
                  color: Colors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Revenue by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No revenue data yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...categories.map(
              (category) => _buildCategoryItem(category, totalRevenue),
            ),
        ],
      ),
    );
  }

  // ✅ FIXED: Pass totalRevenue as parameter
  Widget _buildCategoryItem(
    CategoryRevenueEntity category,
    double totalRevenue,
  ) {
    final percentage = totalRevenue > 0
        ? (category.totalRevenue / totalRevenue * 100)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Text(
                '\$${category.totalRevenue.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2ED573),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2ED573),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}% • ${category.itemCount} items',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard(List<OrderStatusEntity> statuses) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.status, color: Colors.blue, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Order Status Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (statuses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No orders yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statuses
                  .map((status) => _buildOrderStatusChip(status))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ✅ RENAMED: From _buildStatusChip to _buildOrderStatusChip
  Widget _buildOrderStatusChip(OrderStatusEntity status) {
    Color color;
    switch (status.status) {
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'CONFIRMED':
        color = Colors.teal;
        break;
      case 'PROCESSING':
        color = Colors.blue;
        break;
      case 'SHIPPED':
        color = Colors.purple;
        break;
      case 'DELIVERED':
        color = const Color(0xFF2ED573);
        break;
      case 'CANCELLED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '${status.status} (${status.count})',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockCard(List<LowStockProductEntity> products) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.warning_2,
                  color: Colors.red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Low Stock Alert',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Text(
                '${products.length} items',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.tick_circle,
                      color: Color(0xFF2ED573),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'All products well stocked',
                      style: TextStyle(color: Color(0xFF2ED573)),
                    ),
                  ],
                ),
              ),
            )
          else
            ...products.take(5).map((product) => _buildLowStockItem(product)),
        ],
      ),
    );
  }

  Widget _buildLowStockItem(LowStockProductEntity product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Iconsax.image,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ),
                  )
                : const Icon(Iconsax.image, color: Colors.grey, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.categoryName != null)
                  Text(
                    product.categoryName!,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${product.stock} left',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSignupsCard(List<RecentSignupEntity> users) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.user_add,
                  color: Colors.teal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Recent Signups',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (users.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No recent signups',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...users.map((user) => _buildSignupItem(user)),
        ],
      ),
    );
  }

  Widget _buildSignupItem(RecentSignupEntity user) {
    final timeAgo = _getTimeAgo(user.joinedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[200],
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (user.isVerified)
                      const Icon(
                        Iconsax.tick_circle,
                        color: Color(0xFF2ED573),
                        size: 12,
                      ),
                  ],
                ),
                Text(
                  user.phoneNumber,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: TextStyle(fontSize: 10, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Markets',
                Iconsax.box_1,
                Colors.blueAccent,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminMarketsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Categories',
                Iconsax.category,
                Colors.purpleAccent,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminCategoriesScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'FAQ',
                Iconsax.message_question,
                Colors.teal,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminFaqScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Colors',
                Iconsax.colorfilter,
                Colors.pinkAccent,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminColorsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Users',
                Iconsax.image,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Sizes',
                Iconsax.ruler,
                Colors.indigo,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminSizesScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      buildWhen: (prev, current) =>
          current is AdminOrdersLoading ||
          current is AdminOrdersLoaded ||
          current is AdminOrdersError,
      builder: (context, state) {
        if (state is AdminOrdersLoading || state is AdminInitial) {
          return const RecentOrdersSkeleton();
        }

        if (state is AdminOrdersLoaded) {
          final recentOrders = state.orders.take(5).toList();
          if (recentOrders.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'No recent orders yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: recentOrders
                  .map((order) => _buildOrderTile(order))
                  .toList(),
            ),
          );
        }

        if (state is AdminOrdersError) {
          return _buildErrorCard('Failed to load orders', () {
            context.read<AdminBloc>().add(FetchAllOrdersEvent());
          });
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOrderTile(dynamic order) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orangeAccent.withValues(alpha: 0.1),
            child: const Icon(
              Iconsax.shopping_cart,
              color: Colors.orangeAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  '${order.customerName} - \$${order.totalAmount}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildStringStatusChip(order.status),
        ],
      ),
    );
  }

  // ✅ RENAMED: From _buildStatusChip to _buildStringStatusChip
  Widget _buildStringStatusChip(String status) {
    Color color;
    switch (status) {
      case 'PENDING':
        color = Colors.orangeAccent;
        break;
      case 'CONFIRMED':
        color = Colors.teal;
        break;
      case 'PROCESSING':
        color = Colors.blueAccent;
        break;
      case 'SHIPPED':
        color = Colors.purpleAccent;
        break;
      case 'DELIVERED':
        color = AppTheme.primaryColor;
        break;
      case 'CANCELLED':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.warning_2, size: 40, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Iconsax.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCardSkeleton extends StatelessWidget {
  const _AnalyticsCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF2ED573)),
      ),
    );
  }
}

class _AdminNotificationIcon extends StatelessWidget {
  final int cachedCount;
  final bool hasLoadedOnce;

  const _AdminNotificationIcon({
    required this.cachedCount,
    required this.hasLoadedOnce,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      buildWhen: (previous, current) {
        if (previous is NotificationsLoaded && current is NotificationsLoaded) {
          return previous.unreadCount != current.unreadCount;
        }
        if (previous is NotificationsLoading &&
            current is NotificationsLoaded) {
          return true;
        }
        return false;
      },
      builder: (context, state) {
        int unreadCount = cachedCount;

        if (state is NotificationsLoaded) {
          unreadCount = state.unreadCount;
        }

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Iconsax.notification,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  ).then((_) {
                    if (context.mounted) {
                      context.read<NotificationsBloc>().add(
                        LoadNotifications(),
                      );
                    }
                  });
                },
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4757),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
