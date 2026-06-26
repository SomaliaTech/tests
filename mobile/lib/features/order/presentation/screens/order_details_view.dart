import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/order/presentation/widgets/details/bottom_actions.dart';
import 'package:mobile/features/order/presentation/widgets/details/info_card.dart';
import 'package:mobile/features/order/presentation/widgets/details/notes_card.dart';
import 'package:mobile/features/order/presentation/widgets/details/order_item_card.dart';
import 'package:mobile/features/order/presentation/widgets/details/payment_status.dart';
import 'package:mobile/features/order/presentation/widgets/details/price_summary.dart';
import 'package:mobile/features/order/presentation/widgets/details/status_badge.dart';
import 'package:mobile/features/tracking/presentation/screens/tracking_screen.dart';
import '../bloc/order_details_bloc.dart';
import '../bloc/order_details_event.dart';
import '../bloc/order_details_state.dart';

// ✅ Convert to StatefulWidget to use initState
class OrderDetailsView extends StatefulWidget {
  final String orderId;

  const OrderDetailsView({super.key, required this.orderId});

  @override
  State<OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<OrderDetailsView> {
  @override
  void initState() {
    super.initState();
    // ✅ Dispatch load event when view initializes
    context.read<OrderDetailsBloc>().add(LoadOrderDetailsEvent(widget.orderId));
  }

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
        centerTitle: false,
      ),
      body: BlocBuilder<OrderDetailsBloc, OrderDetailsState>(
        builder: (context, state) {
          if (state is OrderDetailsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ED573)),
            );
          }

          if (state is OrderDetailsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.warning_2, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<OrderDetailsBloc>().add(
                        LoadOrderDetailsEvent(widget.orderId),
                      );
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

          if (state is OrderDetailsLoaded) {
            final order = state.order;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Card
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
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
                                    order.orderNumber,
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
                                color: Colors.black.withValues(alpha: 0.05),
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
                        if (order.notes != null && order.notes!.isNotEmpty) ...[
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
                BottomActions(
                  order: order,
                  onTrack: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TrackingScreen(orderId: widget.orderId),
                      ),
                    );
                  },
                  onInvoice: () {
                    // Download invoice
                  },
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
