import 'package:flutter/material.dart';
import 'package:mobile/features/tracking/providers/tracking_provider.dart';
import 'package:provider/provider.dart';
import 'tracking_view.dart';

class TrackingScreen extends StatelessWidget {
  final String orderId;

  const TrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrackingProvider()..loadOrder(orderId),
      child: TrackingView(orderId: orderId),
    );
  }
}
