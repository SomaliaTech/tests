import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/presentation/screens/search_results_screen.dart';
import '../blocs/product_bloc.dart';
import '../blocs/product_event.dart';
import '../widgets/home/header.dart';
import '../widgets/home/categories_section.dart';
import '../widgets/home/hot_deals_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductBloc>();
    bloc.add(GetFeaturedProductsEvent());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Header(
            onSearch: (query) {
              if (query.trim().isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SearchResultsScreen(initialQuery: query),
                  ),
                );
              }
            },
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: const [
                CategoriesSection(),
                SizedBox(height: 16),
                HotDealsSection(),
                SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
