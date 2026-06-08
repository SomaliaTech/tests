import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/product_bloc.dart';
import '../blocs/product_event.dart';
import '../widgets/home/header.dart';
import '../widgets/home/categories_section.dart';
import '../widgets/home/hot_deals_section.dart';

class HomeScreen extends StatelessWidget {
  static Route route() {
    return MaterialPageRoute(builder: (context) => const HomeScreen());
  }

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Load categories and featured products only once when screen is created
    context.read<ProductBloc>().add(GetCategoriesEvent());
    context.read<ProductBloc>().add(GetFeaturedProductsEvent());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Header(
            onSearch: (query) {
              if (query != null && query.isNotEmpty) {
                context.read<ProductBloc>().add(SearchProductsEvent(query));
                // Navigate to search results or handle search
              }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: const [
                  // CategoriesSection(),
                  SizedBox(height: 16),
                  HotDealsSection(),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
