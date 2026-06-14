import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/tracking_bloc.dart';
import '../bloc/tracking_event.dart';
import 'tracking_view.dart';
import '../../../../core/services/injection_container.dart';

class TrackingScreen extends StatelessWidget {
  final String orderId;

  const TrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TrackingBloc>()..add(LoadTrackingEvent(orderId)),
      child: TrackingView(orderId: orderId),
    );
  }
}
