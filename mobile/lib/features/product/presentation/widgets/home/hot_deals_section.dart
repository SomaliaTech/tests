import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/presentation/widgets/shared/product_card.dart';
import '../../blocs/product_bloc.dart';
import '../../blocs/product_state.dart';

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
            children: [
              const Text(
                "Hot Deals",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "View All",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2ED573),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          BlocBuilder<ProductBloc, ProductState>(
            // Build ONLY when it relates directly to featured list state changes
            buildWhen: (previous, current) =>
                current is FeaturedProductsLoading ||
                current is FeaturedProductsLoaded ||
                current is FeaturedProductsError,
            builder: (context, state) {
              if (state is FeaturedProductsLoaded) {
                if (state.products.isEmpty) {
                  return const Center(child: Text("No hot deals found."));
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
                return const Center(child: CircularProgressIndicator());
              } else if (state is FeaturedProductsError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
