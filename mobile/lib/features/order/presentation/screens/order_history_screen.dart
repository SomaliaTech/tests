import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/order/presentation/bloc/order_history_event.dart';
import 'package:mobile/features/order/presentation/screens/order_history_view.dart';
import '../bloc/order_history_bloc.dart';
import '../../../../core/services/injection_container.dart';

class OrderHistoryScreen extends StatelessWidget {
  static Route route() {
    return MaterialPageRoute(builder: (context) => const OrderHistoryScreen());
  }

  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<OrderHistoryBloc>()..add(LoadOrdersEvent()),
      child: const OrderHistoryView(),
    );
  }
}
