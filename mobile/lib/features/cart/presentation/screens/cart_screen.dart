import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_bloc.dart';
import 'cart_view.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      // 🚨 CRITICAL FIX: Use .value to reuse the global CartBloc instance.
      // If you use 'create: (context) => sl<CartBloc>()', it creates a NEW
      // instance, and the Header will never know when you delete items!
      value: context.read<CartBloc>(),
      child: const CartView(),
    );
  }
}
