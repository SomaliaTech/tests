import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/domain/entities/admin_order_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_state.dart';

class AdminOrderDetailsScreen extends StatefulWidget {
  final AdminOrderEntity order;

  const AdminOrderDetailsScreen({super.key, required this.order});

  @override
  State<AdminOrderDetailsScreen> createState() =>
      _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  late AdminOrderEntity _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
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
        title: Text(
          'Order #${_currentOrder.orderNumber}',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminStatusUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            // ✅ Update the local order with the new status
            setState(() {
              _currentOrder = _currentOrder.copyWith(status: state.newStatus);
            });
            // ✅ Refresh orders list in background
            context.read<AdminBloc>().add(const FetchAllOrdersEvent());
          } else if (state is AdminStatusUpdateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminOrdersLoaded) {
            // Convert AdminOrderModel to AdminOrderEntity if needed
            final updatedOrder = state.orders
                .cast<AdminOrderEntity>()
                .firstWhere(
                  (o) => o.id == _currentOrder.id,
                  orElse: () => _currentOrder, // ✅ Now returns same type
                );
            // ✅ Update local order if found
            if (updatedOrder.id == _currentOrder.id &&
                updatedOrder.status != _currentOrder.status) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _currentOrder = updatedOrder;
                });
              });
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Section
                _buildSection('Status', _buildStatusSection()),
                const SizedBox(height: 16),
                // Customer Info
                _buildSection('Customer Information', _buildCustomerInfo()),
                const SizedBox(height: 16),
                // Shipping Address
                if (_currentOrder.shippingAddress != null &&
                    _currentOrder.shippingAddress!.isNotEmpty) ...[
                  _buildSection('Shipping Address', _buildShippingAddress()),
                  const SizedBox(height: 16),
                ],
                // Order Items
                _buildSection('Order Items', _buildOrderItems()),
                const SizedBox(height: 16),
                // Payment Info
                _buildSection('Payment Information', _buildPaymentInfo()),
                const SizedBox(height: 16),
                // Notes
                if (_currentOrder.notes != null &&
                    _currentOrder.notes!.isNotEmpty) ...[
                  _buildSection('Customer Notes', _buildNotes()),
                  const SizedBox(height: 16),
                ],
                // Total
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '\$${_currentOrder.totalAmount}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Update Status Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showStatusUpdateSheet(context),
                    icon: const Icon(Iconsax.edit_2),
                    label: const Text('Update Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ... [Rest of your widget methods remain the same]
  // Only change _buildStatusSection to use _currentOrder

  Widget _buildSection(String title, Widget content) {
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoItem('Order Status', _currentOrder.status),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                'Payment Status',
                _currentOrder.paymentStatus ?? 'PENDING',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ✅ Updated date display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(Iconsax.calendar, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                _formatDate(_currentOrder.createdAt),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Helper method to format date with proper timezone conversion
  String _formatDate(DateTime date) {
    // Convert UTC to local time
    final localDate = date.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);

    if (difference.inDays == 0) {
      return 'Today ${_formatTime(localDate)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${_formatTime(localDate)}';
    } else if (difference.inDays < 7) {
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return '${days[localDate.weekday - 1]} ${_formatTime(localDate)}';
    } else {
      return '${localDate.day}/${localDate.month}/${localDate.year} ${_formatTime(localDate)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  Widget _buildCustomerInfo() {
    return Column(
      children: [
        _buildInfoRow(Iconsax.user, 'Name', _currentOrder.customerName),
        const SizedBox(height: 12),
        if (_currentOrder.customerPhone != null &&
            _currentOrder.customerPhone!.isNotEmpty) ...[
          _buildInfoRow(Iconsax.call, 'Phone', _currentOrder.customerPhone!),
          const SizedBox(height: 12),
        ],
        if (_currentOrder.customerEmail != null &&
            _currentOrder.customerEmail!.isNotEmpty)
          _buildInfoRow(Iconsax.message, 'Email', _currentOrder.customerEmail!),
      ],
    );
  }

  Widget _buildShippingAddress() {
    return _buildInfoRow(
      Iconsax.location,
      'Address',
      _currentOrder.shippingAddress!,
      isMultiline: true,
    );
  }

  Widget _buildOrderItems() {
    return Column(
      children: [
        _buildInfoRow(
          Iconsax.box_1,
          'Items',
          '${_currentOrder.itemsCount} item(s)',
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          Iconsax.shopping_bag,
          'Products',
          _currentOrder.itemNames,
          isMultiline: true,
        ),
      ],
    );
  }

  Widget _buildPaymentInfo() {
    return Column(
      children: [
        _buildInfoRow(
          Iconsax.wallet_money,
          'Method',
          _currentOrder.paymentMethod ?? 'N/A',
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          Iconsax.status,
          'Status',
          _currentOrder.paymentStatus ?? 'PENDING',
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.note_2, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _currentOrder.notes!,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        const SizedBox(width: 12),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: isMultiline ? null : 1,
                overflow: isMultiline ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(value).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: _getStatusColor(value),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange[700]!;
      case 'CONFIRMED':
      case 'PROCESSING':
        return Colors.purple[700]!;
      case 'SHIPPED':
        return Colors.blue[700]!;
      case 'DELIVERED':
      case 'PAID':
        return Colors.green[700]!;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  void _showStatusUpdateSheet(BuildContext context) {
    final statuses = [
      'PENDING',
      'CONFIRMED',
      'PROCESSING',
      'SHIPPED',
      'DELIVERED',
      'CANCELLED',
    ];

    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: screenHeight * 0.75,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Update Order Status',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Order #${_currentOrder.orderNumber}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: statuses.length,
                  itemBuilder: (context, index) {
                    final status = statuses[index];
                    final isSelected = _currentOrder.status == status;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isSelected ? Iconsax.tick_circle5 : Iconsax.square,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey[600],
                        ),
                        title: Text(
                          status,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.read<AdminBloc>().add(
                            UpdateOrderStatusEvent(_currentOrder.id, status),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
