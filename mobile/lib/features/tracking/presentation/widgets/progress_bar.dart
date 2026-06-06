import 'package:flutter/material.dart';
import 'package:mobile/features/tracking/data/models/tracking_model.dart';

class ProgressBar extends StatelessWidget {
  final TrackingStatus currentStatus;

  const ProgressBar({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final statusOrder = [
      TrackingStatus.processing,
      TrackingStatus.shipped,
      TrackingStatus.outForDelivery,
      TrackingStatus.delivered,
    ];

    final currentIndex = statusOrder.indexOf(currentStatus);

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
      child: Row(
        children: statusOrder.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          final isCompleted = index <= currentIndex;
          final isCurrent = index == currentIndex;

          return Expanded(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Line connector
                    if (index < statusOrder.length - 1)
                      Positioned(
                        left: 30,
                        right: -30,
                        child: Container(
                          height: 3,
                          color: index < currentIndex
                              ? const Color(0xFF2ED573)
                              : const Color(0xFFF0F0F0),
                        ),
                      ),
                    // Step icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? const Color(0xFF2ED573)
                            : const Color(0xFFF0F0F0),
                        border: isCurrent
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2ED573,
                                  ).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.circle,
                        size: 18,
                        color: isCompleted
                            ? Colors.white
                            : const Color(0xFFCCCCCC),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  status == TrackingStatus.outForDelivery
                      ? 'Delivery'
                      : status.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isCompleted
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isCompleted
                        ? const Color(0xFF333333)
                        : const Color(0xFF999999),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
