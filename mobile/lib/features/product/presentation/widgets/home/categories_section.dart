import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/product_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/product_state.dart';
import 'package:mobile/features/product/presentation/widgets/home/category_item.dart';
import 'package:toastification/toastification.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Categories",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all categories
                },
                child: const Text(
                  "View All",
                  style: TextStyle(
                    color: Color(0xFF2ED573),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          BlocBuilder<ProductBloc, ProductState>(
            // 🟢 FIX 1: Only rebuild this widget for category-specific state changes
            buildWhen: (previous, current) =>
                current is CategoriesLoading ||
                current is CategoriesLoaded ||
                current is CategoriesError ||
                (current is ProductLoading &&
                    previous
                        is ProductInitial), // Optional: only show initial generic loader
            builder: (context, state) {
              if (state is CategoriesLoaded) {
                final displayCategories = state.categories.take(8).toList();

                // 🟢 FIX 2: Removed the strict constraint height on the parent SizedBox
                // GridView with childAspectRatio needs space to calculate its bounds properly
                return GridView.builder(
                  padding: const EdgeInsets.only(top: 5),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: displayCategories.length,
                  itemBuilder: (context, index) {
                    return CategoryItem(category: displayCategories[index]);
                  },
                );
              } else if (state is CategoriesLoading ||
                  state is ProductLoading) {
                return const Center(
                  child: SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              } else if (state is CategoriesError || state is ProductError) {
                // Safely grab the error message depending on which state came through
                final errMsg = state is CategoriesError
                    ? state.message
                    : (state as ProductError).message;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  toastification.show(
                    title: const Text('Error'),
                    description: Text(errMsg),
                    type: ToastificationType.error,
                    style: ToastificationStyle.fillColored,
                    autoCloseDuration: const Duration(seconds: 3),
                  );
                });
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(errMsg),
                  ),
                );
              }

              // If another unrelated state is emitted, BlocBuilder won't trigger
              // due to buildWhen, but we keep a safe fallback UI layout just in case.
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
