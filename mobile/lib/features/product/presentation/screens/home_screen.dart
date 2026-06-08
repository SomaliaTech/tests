import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/product_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/product_event.dart';
import 'package:toastification/toastification.dart';

import '../widgets/home/header.dart';
import '../widgets/home/categories_section.dart';
import '../widgets/home/hot_deals_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fetch home data cleanly right when view loads
    final bloc = context.read<ProductBloc>();
    bloc.add(GetCategoriesEvent());
    bloc.add(GetFeaturedProductsEvent());

    return ToastificationWrapper(
      child: Scaffold(
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
      ),
    );
  }
}
