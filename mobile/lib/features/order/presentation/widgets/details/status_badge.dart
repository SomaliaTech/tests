import 'package:flutter/material.dart';
import 'package:mobile/features/order/domain/entities/order_details.dart';

class StatusBadge extends StatelessWidget {
  final OrderDetailStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: status.textColor,
        ),
      ),
    );
  }
}
