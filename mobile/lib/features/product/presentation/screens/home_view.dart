import 'package:flutter/material.dart';
import 'package:mobile/features/product/presentation/widgets/home/categories_section.dart';
import 'package:mobile/features/product/presentation/widgets/home/header.dart';
import 'package:mobile/features/product/presentation/widgets/home/hot_deals_section.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: const [
                  CategoriesSection(),
                  SizedBox(height: 16),
                  HotDealsSection(),
                  SizedBox(height: 100), // Space for bottom navigation
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
