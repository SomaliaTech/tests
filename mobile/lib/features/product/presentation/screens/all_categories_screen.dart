import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/product_bloc.dart';
import '../blocs/product_event.dart';
import '../blocs/product_state.dart';

import 'category_screen.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'All Categories',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is CategoriesLoaded) {
            return GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 20,
                childAspectRatio: 0.85,
              ),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryScreen(
                          categoryId: category.id,
                          categoryName: category.name,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.09),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForCategory(category.name),
                          size: 34,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (state is ProductLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProductError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProductBloc>().add(GetCategoriesEvent());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ED573),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('electronic') ||
        lowerName.contains('smartphone') ||
        lowerName.contains('laptop')) {
      return Icons.phone_android;
    }
    if (lowerName.contains('fashion') || lowerName.contains('clothing')) {
      return Icons.checkroom;
    }
    if (lowerName.contains('home') || lowerName.contains('kitchen')) {
      return Icons.home;
    }
    if (lowerName.contains('beauty') || lowerName.contains('cosmetic')) {
      return Icons.brush;
    }
    if (lowerName.contains('sport') || lowerName.contains('fitness')) {
      return Icons.sports_basketball;
    }
    if (lowerName.contains('health') || lowerName.contains('wellness')) {
      return Icons.health_and_safety;
    }
    if (lowerName.contains('book') || lowerName.contains('media')) {
      return Icons.book;
    }
    if (lowerName.contains('toy') || lowerName.contains('game')) {
      return Icons.toys;
    }
    if (lowerName.contains('internet') || lowerName.contains('wifi')) {
      return Icons.wifi;
    }

    return Icons.category;
  }
}
