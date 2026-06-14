import 'package:flutter/material.dart';
import 'package:mobile/features/tracking/data/models/tracking_model.dart';
import 'package:mobile/features/tracking/domain/entities/tracking.dart';

class StatusBadge extends StatelessWidget {
  final TrackingStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.borderColor, width: 1),
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
