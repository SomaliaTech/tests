import 'package:flutter/material.dart';
import 'package:mobile/features/orders_details/presentation/widgets/bottom_actions.dart';
import 'package:mobile/features/orders_details/presentation/widgets/info_card.dart';
import 'package:mobile/features/orders_details/presentation/widgets/notes_card.dart';
import 'package:mobile/features/orders_details/presentation/widgets/order_item_card.dart';
import 'package:mobile/features/orders_details/presentation/widgets/payment_status.dart';
import 'package:mobile/features/orders_details/presentation/widgets/price_summary.dart';
import 'package:mobile/features/orders_details/presentation/widgets/status_badge.dart';
import 'package:mobile/features/orders_details/presentation/providers/order_details_provider.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

class OrderDetailsView extends StatelessWidget {
  final String orderId;

  const OrderDetailsView({super.key, required this.orderId});

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
          'Order Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.share, color: Color(0xFF333333)),
            onPressed: () {
              context.read<OrderDetailsProvider>().shareOrder();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing order...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<OrderDetailsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ED573)),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.warning_2, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshOrder(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ED573),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!provider.hasOrder) {
            return const Center(child: Text('Order not found'));
          }

          final order = provider.order!;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      // Status Card
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.id,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.formattedDate,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                            StatusBadge(status: order.status),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Order Items
                      const Text(
                        'Order Items',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: order.items
                              .map((item) => OrderItemCard(item: item))
                              .toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Price Summary
                      const Text(
                        'Price Summary',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PriceSummary(
                        subtotal: order.subtotal,
                        shippingFee: order.shippingFee,
                        discount: order.discount,
                        total: order.total,
                      ),

                      const SizedBox(height: 20),

                      // Delivery Information
                      const Text(
                        'Delivery Information',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InfoCard(
                        title: '',
                        rows: [
                          InfoRowData(
                            icon: Iconsax.user,
                            label: 'Recipient Name',
                            value: order.recipientName,
                          ),
                          InfoRowData(
                            icon: Iconsax.call,
                            label: 'Phone Number',
                            value: order.recipientPhone,
                          ),
                          InfoRowData(
                            icon: Iconsax.location,
                            label: 'Delivery Address',
                            value: order.deliveryAddress,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Payment Information
                      const Text(
                        'Payment Information',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PaymentStatusWidget(
                        status: order.paymentStatus,
                        method: order.paymentMethod,
                      ),

                      // Order Notes
                      if (order.notes != null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Order Notes',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 12),
                        NotesCard(notes: order.notes!),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              BottomActions(
                order: order,
                onReorder: () {
                  provider.reorder();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reordering items...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                onTrack: () {
                  provider.navigateToTracking(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening tracking...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                onInvoice: () {
                  provider.downloadInvoice();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Downloading invoice...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
