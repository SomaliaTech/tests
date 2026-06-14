import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/order/presentation/screens/order_details_view.dart';
import '../bloc/order_details_bloc.dart';
import '../bloc/order_details_event.dart';
import '../../../../core/services/injection_container.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<OrderDetailsBloc>()..add(LoadOrderDetailsEvent(orderId)),
      child: OrderDetailsView(orderId: orderId),
    );
  }
}
