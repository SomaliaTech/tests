import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_event.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_state.dart';
import 'package:mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:mobile/features/notifications/presentation/screens/notifications_screen.dart';

class Header extends StatefulWidget {
  final Function(String)? onSearch;

  const Header({super.key, this.onSearch});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  void initState() {
    super.initState();
    // Load cart only once when the widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartBloc>().add(LoadCartEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2ED573),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "HALDOOR",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Iconsax.notification,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 5),
                      BlocBuilder<CartBloc, CartState>(
                        buildWhen: (previous, current) {
                          // Only rebuild when cart items change
                          return current is CartLoaded || current is CartError;
                        },
                        builder: (context, state) {
                          int itemCount = 0;

                          if (state is CartLoaded) {
                            itemCount = state.itemCount;
                          }

                          return Stack(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CartScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Iconsax.shopping_cart,
                                  color: Colors.white,
                                ),
                              ),
                              if (itemCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF4757),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      itemCount > 99
                                          ? '99+'
                                          : itemCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  onSubmitted: widget.onSearch,
                  decoration: InputDecoration(
                    hintText: "Search product here",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(
                      Iconsax.search_normal,
                      color: Colors.grey,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
