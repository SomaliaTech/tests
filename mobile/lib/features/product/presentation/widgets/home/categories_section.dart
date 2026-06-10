import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/common/widgets/loading_category.dart';
import 'package:mobile/features/product/presentation/screens/all_categories_screen.dart';
import 'package:mobile/features/product/presentation/widgets/home/category_item.dart';

import 'package:toastification/toastification.dart';
import '../../blocs/category_bloc.dart';
import '../../blocs/category_event.dart';
import '../../blocs/category_state.dart';
import '../../../../../core/services/injection_container.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CategoryBloc>()..add(GetParentCategoriesEvent()),
      child: Container(
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllCategoriesScreen(),
                      ),
                    );
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
            BlocBuilder<CategoryBloc, CategoryState>(
              buildWhen: (previous, current) =>
                  current is ParentCategoriesLoaded ||
                  current is CategoriesLoading ||
                  current is CategoryError,
              builder: (context, state) {
                if (state is ParentCategoriesLoaded) {
                  final displayCategories = state.categories.take(8).toList();
                  return GridView.builder(
                    padding: const EdgeInsets.only(top: 5),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: displayCategories.length,
                    itemBuilder: (context, index) {
                      final category = displayCategories[index];
                      return CategoryItem(category: category);
                    },
                  );
                } else if (state is CategoriesLoading) {
                  return const LoadingCategory();
                } else if (state is CategoryError) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    toastification.show(
                      title: const Text('Error'),
                      description: Text(state.message),
                      type: ToastificationType.error,
                      style: ToastificationStyle.fillColored,
                      autoCloseDuration: const Duration(seconds: 3),
                    );
                  });
                  return const SizedBox.shrink();
                }
                return const LoadingCategory();
              },
            ),
          ],
        ),
      ),
    );
  }
}
