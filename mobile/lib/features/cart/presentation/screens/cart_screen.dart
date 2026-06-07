import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../../domain/usecases/clear_cart.dart';
import '../../domain/usecases/get_cart_items.dart';
import '../../domain/usecases/get_cart_summary.dart';
import '../../domain/usecases/remove_item.dart';
import '../../domain/usecases/update_quantity.dart';
import '../../data/datasources/cart_local_datasource.dart';
import '../../data/repositories/cart_repository_impl.dart';
import 'cart_view.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize dependencies
    final localDataSource = CartLocalDataSource();
    final repository = CartRepositoryImpl(localDataSource: localDataSource);

    return MultiBlocProvider(
      providers: [
        BlocProvider<CartBloc>(
          create: (context) => CartBloc(
            getCartItems: GetCartItems(repository),
            updateQuantity: UpdateQuantity(repository),
            removeItem: RemoveItem(repository),
            clearCart: ClearCart(repository),
            getCartSummary: const GetCartSummary(),
          )..add(LoadCart()),
        ),
      ],
      child: const CartView(),
    );
  }
}
