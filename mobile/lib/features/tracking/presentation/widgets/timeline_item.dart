import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/tracking/domain/entities/tracking.dart';

class TimelineItem extends StatelessWidget {
  final TrackingStep step;
  final bool isLast;
  final bool isLatest;

  const TimelineItem({
    super.key,
    required this.step,
    required this.isLast,
    required this.isLatest,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline left column
        SizedBox(
          width: 35,
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLatest
                      ? const Color(0xFF2ED573)
                      : const Color(0xFFF0F0F0),
                ),
                child: Icon(
                  Iconsax.tick_circle,
                  size: 12,
                  color: isLatest ? Colors.white : const Color(0xFF999999),
                ),
              ),
              if (!isLast)
                Container(width: 2, height: 80, color: const Color(0xFFEEEEEE)),
            ],
          ),
        ),
        // Timeline content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isLatest
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isLatest
                              ? const Color(0xFF2ED573)
                              : const Color(0xFF333333),
                        ),
                      ),
                    ),
                    Text(
                      '${step.formattedDate} • ${step.formattedTime}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.location,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),
                if (step.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
