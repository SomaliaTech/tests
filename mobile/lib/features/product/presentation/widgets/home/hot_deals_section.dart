import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/common/widgets/empty_state_widget.dart';
import 'package:mobile/core/common/widgets/shared/products_grid_skeleton.dart';
import 'package:mobile/features/product/presentation/blocs/product_event.dart';

import '../../blocs/product_bloc.dart';
import '../../blocs/product_state.dart';
import '../shared/product_card.dart';

class HotDealsSection extends StatelessWidget {
  const HotDealsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Hot Deals",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              // TextButton removed temporarily
            ],
          ),
          const SizedBox(height: 15),
          BlocBuilder<ProductBloc, ProductState>(
            buildWhen: (previous, current) =>
                current is FeaturedProductsLoaded ||
                current is FeaturedProductsLoading ||
                current is FeaturedProductsError,
            builder: (context, state) {
              if (state is FeaturedProductsLoaded) {
                if (state.products.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No Hot Deals',
                    message: 'Check back later for amazing deals!',
                    icon: Icons.local_fire_department,
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 15,
                    mainAxisExtent: 250,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: state.products[index]);
                  },
                );
              } else if (state is FeaturedProductsLoading) {
                return const ProductsGridSkeleton();
              } else if (state is FeaturedProductsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ProductBloc>().add(
                            GetFeaturedProductsEvent(),
                          );
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
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
