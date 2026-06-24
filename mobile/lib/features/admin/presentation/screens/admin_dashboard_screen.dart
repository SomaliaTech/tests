import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/domain/entities/chart_data_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_state.dart';
import 'package:mobile/features/admin/presentation/screens/admin_main_navigation_screen.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_event.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_state.dart';
import 'package:mobile/features/admin/presentation/screens/admin_revenue_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:mobile/features/admin/presentation/widgets/dashboard_widgets.dart';
import 'package:mobile/features/admin/presentation/widgets/skeleton_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ValueNotifier<String> _periodNotifier = ValueNotifier('week');
  StreamSubscription? _dashboardSubscription;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(
      const LoadDashboardDataEvent(period: 'week'),
    );
    context.read<AdminBloc>().add(FetchAllOrdersEvent());

    _dashboardSubscription = context.read<DashboardBloc>().stream.listen((
      state,
    ) {
      if (mounted && state is DashboardLoaded) {
        _periodNotifier.value = state.period;
      }
    });
  }

  @override
  void dispose() {
    _dashboardSubscription?.cancel();
    _periodNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(context),
                  const SizedBox(height: 16),
                  _buildStatsSection(context),
                  const SizedBox(height: 24),
                  _buildChartsSection(context),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Quick Management'),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Recent Orders'),
                  const SizedBox(height: 12),
                  _buildRecentOrders(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Iconsax.arrow_left,
                    color: Color(0xFF2ED573),
                    size: 24,
                  ),
                ),
              ),
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Iconsax.notification,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
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
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
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
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        period.toString().toUpperCase(),
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

  Widget _buildStatsSection(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const StatsSkeleton();
        }

        if (state is DashboardLoaded) {
          return Container(
            constraints: const BoxConstraints(minHeight: 180),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                DashboardStatCard(
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
                DashboardStatCard(
                  title: 'Total Orders',
                  value: state.stats.totalOrders.toString(),
                  trend: state.stats.orderGrowth,
                  icon: Iconsax.shopping_cart,
                  color: Colors.orangeAccent,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AdminMainNavigationScreen(initialIndex: 2),
                      ),
                    );
                  },
                ),
                DashboardStatCard(
                  title: 'Revenue',
                  value: '\$${state.stats.totalRevenue.toStringAsFixed(0)}',
                  trend: state.stats.revenueGrowth,
                  icon: Iconsax.money_tick,
                  color: AppTheme.primaryColor,
                  onPressed: () {
                    print("object");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminRevenueScreen(),
                      ),
                    );
                  },
                ),
                DashboardStatCard(
                  title: 'New Users',
                  value: state.stats.newUsers.toString(),
                  trend: state.stats.newUserGrowth,
                  icon: Iconsax.user_add,
                  color: Colors.purpleAccent,
                  onPressed: () {},
                ),
              ],
            ),
          );
        }

        if (state is DashboardError) {
          return Center(
            child: Column(
              children: [
                const Icon(Iconsax.warning_2, size: 40, color: Colors.red),
                const SizedBox(height: 8),
                Text(
                  'Failed to load stats',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextButton(
                  onPressed: () {
                    context.read<DashboardBloc>().add(
                      const LoadDashboardDataEvent(period: 'week'),
                    );
                  },
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
              DashboardBarChart(
                title: 'Device Traffic',
                data: state.deviceTraffic
                    .map(
                      (e) => ChartDataEntity(
                        date: e.device,
                        value: e.value.toDouble(),
                        count: 0,
                      ),
                    )
                    .toList(),
                xLabels: state.deviceTraffic.map((e) => e.device).toList(),
              ),
            ],
          );
        }

        if (state is DashboardError) {
          return Center(
            child: Column(
              children: [
                const Icon(Iconsax.warning_2, size: 40, color: Colors.red),
                const SizedBox(height: 8),
                Text(
                  'Failed to load charts',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextButton(
                  onPressed: () {
                    context.read<DashboardBloc>().add(
                      const LoadDashboardDataEvent(period: 'week'),
                    );
                  },
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            'Products',
            Iconsax.box_1,
            Colors.blueAccent,
            () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AdminMainNavigationScreen(initialIndex: 1),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            context,
            'Orders',
            Iconsax.shopping_cart,
            Colors.orangeAccent,
            () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AdminMainNavigationScreen(initialIndex: 2),
                ),
              );
            },
          ),
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
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
                  color: Colors.grey.withOpacity(0.05),
                  spreadRadius: 1,
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
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Iconsax.warning_2, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Failed to load orders',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextButton(
                  onPressed: () {
                    context.read<AdminBloc>().add(FetchAllOrdersEvent());
                  },
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

  Widget _buildOrderTile(dynamic order) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orangeAccent.withOpacity(0.1),
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
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${order.customerName} - \$${order.totalAmount}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildStatusChip(order.status),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
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
        color: color.withOpacity(0.1),
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
