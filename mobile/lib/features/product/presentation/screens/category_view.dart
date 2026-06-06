import 'package:flutter/material.dart';
import 'package:mobile/features/product/presentation/widgets/category/category_header.dart';
import 'package:mobile/features/product/presentation/widgets/shared/products_grid.dart';
import 'package:mobile/features/product/presentation/widgets/category/sub_category_item.dart';
import 'package:mobile/features/product/presentation/providers/category_provider.dart';
import 'package:provider/provider.dart';

class CategoryView extends StatelessWidget {
  final String slug;

  const CategoryView({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          final category = provider.category;

          if (category == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ED573)),
            );
          }

          return Column(
            children: [
              CategoryHeader(
                title: category.title,
                onBackPressed: () => Navigator.pop(context),
                onCartPressed: () {
                  provider.onCartPressed();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening cart...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sub Categories Section
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFEEEEEE),
                              width: 1,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            children: category.subCategories.map((subCategory) {
                              return SubCategoryItem(
                                id: subCategory.id,
                                name: subCategory.name,
                                iconUrl: subCategory.iconUrl,
                                isSelected:
                                    provider.selectedSubCategoryId ==
                                    subCategory.id,
                                onTap: () =>
                                    provider.toggleSubCategory(subCategory.id),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Products Section
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${category.title} Category',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 15),
                            ProductsGrid(
                              prodcut: provider.getFilteredProducts(),
                              // onProductTap: (product) {
                              //   provider.onProductTap(product);
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     SnackBar(
                              //       content: Text('Opening ${product.name}...'),
                              //       duration: const Duration(seconds: 1),
                              //     ),
                              //   );
                              // },
                            ),
                            const SizedBox(height: 100), // Bottom padding
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
