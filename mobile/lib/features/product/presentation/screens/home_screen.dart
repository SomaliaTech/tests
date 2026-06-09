import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/product_bloc.dart';
import '../blocs/product_event.dart';
import '../widgets/home/header.dart';
import '../widgets/home/categories_section.dart';
import '../widgets/home/hot_deals_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Only load featured products here (categories are handled by CategoriesSection)
    final bloc = context.read<ProductBloc>();
    bloc.add(GetFeaturedProductsEvent());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Header(
            onSearch: (query) {
              if (query != null && query.isNotEmpty) {
                bloc.add(SearchProductsEvent(query));
              }
            },
          ),
          const Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  CategoriesSection(),
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
