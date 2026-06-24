import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/domain/entities/admin_revenue_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/revenue/revenue_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/revenue/revenue_event.dart';
import 'package:mobile/features/admin/presentation/bloc/revenue/revenue_state.dart';

class AdminRevenueDetailsScreen extends StatefulWidget {
  final String orderId;

  const AdminRevenueDetailsScreen({super.key, required this.orderId});

  @override
  State<AdminRevenueDetailsScreen> createState() =>
      _AdminRevenueDetailsScreenState();
}

class _AdminRevenueDetailsScreenState extends State<AdminRevenueDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RevenueBloc>().add(FetchRevenueDetailsEvent(widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Revenue Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<RevenueBloc, RevenueState>(
        buildWhen: (prev, current) =>
            current is RevenueDetailsLoading ||
            current is RevenueDetailsLoaded ||
            current is RevenueDetailsError,
        builder: (context, state) {
          if (state is RevenueDetailsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (state is RevenueDetailsLoaded) {
            final revenue = state.revenue;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Header Card
                  _buildOrderHeaderCard(revenue),
                  const SizedBox(height: 16),

                  // Customer Info
                  _buildSectionCard(
                    title: 'Customer Information',
                    icon: Iconsax.user,
                    child: Column(
                      children: [
                        _buildInfoRow('Name', revenue.customerName),
                        if (revenue.customerEmail != null)
                          _buildInfoRow('Email', revenue.customerEmail!),
                        if (revenue.customerPhone != null)
                          _buildInfoRow('Phone', revenue.customerPhone!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Shipping Address
                  if (revenue.shippingAddress != null) ...[
                    _buildSectionCard(
                      title: 'Shipping Address',
                      icon: Iconsax.location,
                      child: Text(
                        revenue.shippingAddress!,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Order Items
                  _buildSectionCard(
                    title: 'Order Items (${revenue.items.length})',
                    icon: Iconsax.box_1,
                    child: Column(
                      children: revenue.items
                          .map((item) => _buildItemTile(item))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Info
                  _buildSectionCard(
                    title: 'Payment Information',
                    icon: Iconsax.wallet_money,
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Method',
                          _formatPaymentMethod(revenue.paymentMethod ?? 'N/A'),
                        ),
                        _buildInfoRow('Status', revenue.paymentStatus),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  if (revenue.notes != null && revenue.notes!.isNotEmpty) ...[
                    _buildSectionCard(
                      title: 'Customer Notes',
                      icon: Iconsax.note_2,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Iconsax.note_2,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                revenue.notes!,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Total Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2ED573), Color(0xFF1E90FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildTotalRow(
                          'Subtotal',
                          revenue.subtotal,
                          textColor: Colors.white70,
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 8),
                        _buildTotalRow(
                          'Total',
                          revenue.totalAmount,
                          textColor: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is RevenueDetailsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.warning_2, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load details',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<RevenueBloc>().add(
                        FetchRevenueDetailsEvent(widget.orderId),
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
      ),
    );
  }

  Widget _buildOrderHeaderCard(AdminRevenueEntity revenue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${revenue.orderNumber}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.tick_circle,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PAID',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDateInfo(
                Iconsax.calendar,
                'Order Date',
                _formatFullDate(revenue.createdAt),
              ),
              const SizedBox(width: 16),
              _buildDateInfo(
                Iconsax.clock,
                'Updated',
                _formatFullDate(revenue.updatedAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(AdminRevenueItemEntity item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: item.productImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.productImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Iconsax.image,
                        color: Colors.grey[400],
                        size: 30,
                      ),
                    ),
                  )
                : Icon(Iconsax.box_1, color: Colors.grey[400], size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.category != null)
                  Text(
                    item.category!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item.colorName != null) ...[
                      _buildVariantTag('Color: ${item.colorName}'),
                      const SizedBox(width: 6),
                    ],
                    if (item.sizeName != null)
                      _buildVariantTag('Size: ${item.sizeName}'),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${item.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[700], fontSize: 10),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double value, {
    Color textColor = Colors.white,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: textColor, fontSize: fontSize),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ],
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'evc_plus':
        return 'EVC Plus';
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return method
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (w) => w.isEmpty
                  ? ''
                  : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
            )
            .join(' ');
    }
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $amPm';
  }
}
