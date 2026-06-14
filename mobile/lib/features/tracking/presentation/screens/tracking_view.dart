import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/tracking/domain/entities/tracking.dart';
import '../bloc/tracking_bloc.dart';
import '../bloc/tracking_event.dart';
import '../bloc/tracking_state.dart';
import '../widgets/bottom_actions.dart';
import '../widgets/info_card.dart';
import '../widgets/progress_bar.dart';
import '../widgets/status_badge.dart';
import '../widgets/timeline_item.dart';

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
        centerTitle: false,
      ),
      body: BlocBuilder<TrackingBloc, TrackingState>(
        builder: (context, state) {
          if (state is TrackingLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ED573)),
            );
          }

          if (state is TrackingError) {
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
                      context.read<TrackingBloc>().add(
                        LoadTrackingEvent(orderId),
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

          if (state is TrackingLoaded) {
            final tracking = state.tracking;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        _buildStatusCard(tracking, context),
                        const SizedBox(height: 20),
                        const Text(
                          'Shipment Progress',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 15),
                        ProgressBar(currentStatus: tracking.status),
                        const SizedBox(height: 20),
                        const Text(
                          'Tracking History',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildTimeline(tracking),
                        const SizedBox(height: 20),
                        InfoCard(
                          title: 'Delivery Information',
                          rows: [
                            InfoRow(
                              icon: Iconsax.user,
                              label: 'Recipient',
                              value: tracking.recipientName,
                            ),
                            InfoRow(
                              icon: Iconsax.call,
                              label: 'Phone',
                              value: tracking.recipientPhone,
                            ),
                            InfoRow(
                              icon: Iconsax.location,
                              label: 'Address',
                              value: tracking.deliveryAddress,
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        InfoCard(
                          title: 'Courier Information',
                          rows: [
                            InfoRow(
                              icon: Iconsax.building,
                              label: 'Shipping Company',
                              value: tracking.carrier,
                            ),
                            InfoRow(
                              icon: Iconsax.barcode,
                              label: 'Tracking Number',
                              value: tracking.trackingNumber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                BottomActions(
                  onContactSupport: () {
                    // Contact support
                  },
                  onTrackOnMap: () {
                    // Track on map
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

  Widget _buildStatusCard(TrackingInfo tracking, BuildContext context) {
    return Container(
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
                    tracking.orderNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Placed on ${tracking.formattedDate}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
              StatusBadge(status: tracking.status),
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
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tracking.formattedEstimatedDelivery,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: const Color(0xFFEEEEEE)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${tracking.total.toStringAsFixed(2)}',
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
    );
  }

  Widget _buildTimeline(TrackingInfo tracking) {
    return Container(
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
        children: tracking.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == tracking.steps.length - 1;
          final isLatest = index == 0;

          return TimelineItem(step: step, isLast: isLast, isLatest: isLatest);
        }).toList(),
      ),
    );
  }
}
