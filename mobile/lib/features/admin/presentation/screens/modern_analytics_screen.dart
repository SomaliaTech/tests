// lib/features/admin/presentation/screens/modern_analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../bloc/analytics/analytics_bloc.dart';
import '../bloc/analytics/analytics_event.dart';
import '../bloc/analytics/analytics_state.dart';
import '../../domain/entities/analytics_entities.dart';

class ModernAnalyticsScreen extends StatefulWidget {
  const ModernAnalyticsScreen({super.key});

  @override
  State<ModernAnalyticsScreen> createState() => _ModernAnalyticsScreenState();
}

class _ModernAnalyticsScreenState extends State<ModernAnalyticsScreen> {
  List<DateTime> _selectedDates = [];
  String _viewMode = 'summary'; // 'summary' or 'transactions'

  @override
  void initState() {
    super.initState();
    _setDefaultDates();
  }

  void _setDefaultDates() {
    final now = DateTime.now();
    _selectedDates = List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });
    _loadAnalytics();
  }

  void _loadAnalytics() {
    if (_selectedDates.isNotEmpty) {
      context.read<AnalyticsBloc>().add(
        LoadCustomDatesAnalyticsEvent(_selectedDates),
      );
    }
  }

  void _toggleDate(DateTime date) {
    setState(() {
      final exists = _selectedDates.any((d) => _isSameDay(d, date));
      if (exists) {
        _selectedDates.removeWhere((d) => _isSameDay(d, date));
      } else {
        _selectedDates.add(date);
        _selectedDates.sort((a, b) => a.compareTo(b));
      }
    });
    _loadAnalytics();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Revenue Analytics',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.calendar, color: Color(0xFF6C63FF)),
            onPressed: _pickCustomRange,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Date Selector Strip
          // 1. Date Selector Strip
          Container(
            height:
                100, // ✅ FIX: Increased from 90 to 100 to prevent 1px overflow
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: 14,
              itemBuilder: (context, index) {
                final date = DateTime.now().subtract(
                  Duration(days: 13 - index),
                );
                final isSelected = _selectedDates.any(
                  (d) => _isSameDay(d, date),
                );

                return GestureDetector(
                  onTap: () => _toggleDate(date),
                  child: Container(
                    width: 65,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF6C63FF,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ), // ✅ FIX: Reduced spacing from 4 to 2
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize:
                                20, // ✅ FIX: Reduced font size from 22 to 20
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white70
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 2. View Toggle (Summary / Transactions)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _viewMode = 'summary'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _viewMode == 'summary'
                            ? const Color(0xFF6C63FF).withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _viewMode == 'summary'
                              ? const Color(0xFF6C63FF)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.chart,
                            size: 18,
                            color: _viewMode == 'summary'
                                ? const Color(0xFF6C63FF)
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _viewMode == 'summary'
                                  ? const Color(0xFF6C63FF)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _viewMode = 'transactions'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _viewMode == 'transactions'
                            ? const Color(0xFF6C63FF).withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _viewMode == 'transactions'
                              ? const Color(0xFF6C63FF)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.receipt,
                            size: 18,
                            color: _viewMode == 'transactions'
                                ? const Color(0xFF6C63FF)
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Transactions',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _viewMode == 'transactions'
                                  ? const Color(0xFF6C63FF)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Content Area
          Expanded(
            child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
              builder: (context, state) {
                if (state is AnalyticsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AnalyticsLoaded) {
                  if (_viewMode == 'summary') {
                    return _buildSummaryView(state);
                  } else {
                    return _buildTransactionsView(state);
                  }
                } else if (state is AnalyticsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.warning_2,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAnalytics,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(
                  child: Text('Select dates to view analytics'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView(AnalyticsLoaded state) {
    final dailyRevenue = state.data.dailyRevenue ?? [];
    final totalRevenue = dailyRevenue.fold<double>(
      0,
      (sum, item) => sum + item.revenue,
    );
    final totalOrders = dailyRevenue.fold<int>(
      0,
      (sum, item) => sum + item.orders,
    );
    final avgOrderValue = totalOrders > 0 ? (totalRevenue / totalOrders) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Revenue',
                  '\$${totalRevenue.toStringAsFixed(2)}',
                  Iconsax.dollar_circle,
                  const Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  totalOrders.toString(),
                  Iconsax.shopping_bag,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Avg. Order',
                  '\$${avgOrderValue.toStringAsFixed(2)}',
                  Iconsax.receipt_1,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active Days',
                  _selectedDates.length.toString(),
                  Iconsax.calendar_1,
                  const Color(0xFFEC4899),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Daily Breakdown
          const Text(
            'Daily Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          ...dailyRevenue.map((day) => _buildDailySummaryCard(day)),

          const SizedBox(height: 24),

          // Top Products
          if (state.data.topProducts.isNotEmpty) ...[
            const Text(
              'Top Products',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...state.data.topProducts.take(5).map((p) => _buildProductRow(p)),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsView(AnalyticsLoaded state) {
    final dailyRevenue = state.data.dailyRevenue ?? [];

    if (dailyRevenue.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.receipt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    final transactionsByDate = <String, List<DailyRevenueEntity>>{};
    for (var day in dailyRevenue) {
      transactionsByDate.putIfAbsent(day.date, () => []).add(day);
    }

    return Column(
      children: [
        // Transactions Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${dailyRevenue.length} transactions found',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Export functionality
                },
                icon: const Icon(Iconsax.document_download, size: 18),
                label: const Text('Export'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
        ),

        // Transactions List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dailyRevenue.length,
            itemBuilder: (context, index) {
              final transaction = dailyRevenue[index];
              return _buildTransactionCard(transaction, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(DailyRevenueEntity transaction, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'EEEE, MMM d, y',
                      ).format(DateTime.parse(transaction.date)),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${transaction.orders} orders',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${transaction.revenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 12),

          // Transaction Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Orders', transaction.orders.toString()),
              _buildDetailItem(
                'Revenue',
                '\$${transaction.revenue.toStringAsFixed(2)}',
              ),
              _buildDetailItem(
                'Avg/Order',
                '\$${(transaction.revenue / transaction.orders).toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummaryCard(DailyRevenueEntity day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.parse(day.date)),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${day.orders} orders',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          Text(
            '\$${day.revenue.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(TopProductEntity product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${product.totalSold}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C63FF),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${product.orderCount} orders',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '\$${product.totalRevenue.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDates.isNotEmpty
          ? DateTimeRange(start: _selectedDates.first, end: _selectedDates.last)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6C63FF)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final days = picked.end.difference(picked.start).inDays + 1;
        _selectedDates = List.generate(
          days,
          (index) => picked.start.add(Duration(days: index)),
        );
      });
      _loadAnalytics();
    }
  }
}
