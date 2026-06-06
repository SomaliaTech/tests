import 'package:flutter/material.dart';
import 'package:mobile/features/tracking/presentation/widgets/bottom_actions.dart';
import 'package:mobile/features/tracking/presentation/widgets/info_card.dart';
import 'package:mobile/features/tracking/presentation/widgets/progress_bar.dart';
import 'package:mobile/features/tracking/presentation/widgets/status_badge.dart';
import 'package:mobile/features/tracking/presentation/widgets/timeline_item.dart';
import 'package:mobile/features/tracking/providers/tracking_provider.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

class TrackingView extends StatelessWidget {
  final String orderId;

  const TrackingView({super.key, required this.orderId});

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
          'Tracking Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<TrackingProvider>(
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
            return const Center(child: Text('No order found'));
          }

          final order = provider.order!;
          final stepsInOrder = provider.getStepsInOrder();

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
                        child: Column(
                          children: [
                            Row(
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
                                      'Placed on ${order.formattedDate}',
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
                            const SizedBox(height: 12),
                            const Divider(color: Color(0xFFEEEEEE), height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Estimated Delivery',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.formattedEstimatedDelivery,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: const Color(0xFFEEEEEE),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Amount',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${order.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Progress Bar
                      const SizedBox(height: 20),

                      // Shipment Progress
                      const Text(
                        'Shipment Progress',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 15),
                      ProgressBar(currentStatus: order.status),

                      const SizedBox(height: 20),

                      // Tracking History
                      const Text(
                        'Tracking History',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 15),
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
                          children: stepsInOrder.asMap().entries.map((entry) {
                            final index = entry.key;
                            final step = entry.value;
                            final isLast = index == stepsInOrder.length - 1;
                            final isLatest = index == 0;

                            return TimelineItem(
                              step: step,
                              isLast: isLast,
                              isLatest: isLatest,
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Delivery Information
                      InfoCard(
                        title: 'Delivery Information',
                        rows: [
                          const InfoRow(
                            icon: Iconsax.user,
                            label: 'Recipient',
                            value: 'Eng Soke',
                          ),
                          const InfoRow(
                            icon: Iconsax.call,
                            label: 'Phone',
                            value: '+252 61 673 9858',
                          ),
                          const InfoRow(
                            icon: Iconsax.location,
                            label: 'Address',
                            value:
                                'Hodan District, KM4 Road, Mogadishu, Somalia',
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Courier Information
                      InfoCard(
                        title: 'Courier Information',
                        rows: [
                          const InfoRow(
                            icon: Iconsax.building,
                            label: 'Shipping Company',
                            value: 'SOOMAR Express',
                          ),
                          const InfoRow(
                            icon: Iconsax.barcode,
                            label: 'Tracking Number',
                            value: 'TRK987654321',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              BottomActions(
                onContactSupport: () {
                  provider.contactSupport();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contacting support...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                onTrackOnMap: () {
                  provider.trackOnMap();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening map...'),
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
