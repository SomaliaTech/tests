import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/common/widgets/empty_state_widget.dart';
import 'package:mobile/core/common/widgets/shared/products_grid_skeleton.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/features/product/presentation/blocs/product_event.dart';
import '../../blocs/product_bloc.dart';
import '../../blocs/product_state.dart';
import '../shared/product_card.dart';

class HotDealsSection extends StatefulWidget {
  const HotDealsSection({super.key});

  @override
  State<HotDealsSection> createState() => _HotDealsSectionState();
}

// ✅ ADDED: AutomaticKeepAliveClientMixin
class _HotDealsSectionState extends State<HotDealsSection>
    with AutomaticKeepAliveClientMixin {
  // ✅ REQUIRED: Keep widget alive when scrolled off-screen
  @override
  bool get wantKeepAlive => true;

  bool _wasOffline = false;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  void _loadProducts() {
    if (!mounted) return;

    final bloc = context.read<ProductBloc>();

    // ✅ If data is already loaded in BLoC, do NOT reload
    if (bloc.state is FeaturedProductsLoaded) {
      _hasLoadedOnce = true;
      return;
    }

    bloc.add(const GetFeaturedProductsEvent());
    _hasLoadedOnce = true;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ REQUIRED: Must call super.build when using AutomaticKeepAliveClientMixin
    super.build(context);

    return Padding(
      padding: const EdgeInsets.all(10),
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
            ],
          ),
          const SizedBox(height: 15),
          Consumer<ConnectivityService>(
            builder: (context, connectivity, _) {
              final isOnline = connectivity.status == ConnectionStatus.online;

              // Auto-refresh when internet comes back
              if (isOnline && _wasOffline && _hasLoadedOnce) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadProducts();
                });
              }
              _wasOffline = !isOnline;

              return BlocBuilder<ProductBloc, ProductState>(
                buildWhen: (previous, current) =>
                    current is FeaturedProductsLoaded ||
                    current is FeaturedProductsLoading ||
                    current is FeaturedProductsError,
                builder: (context, state) {
                  // Show loading skeleton
                  if (state is FeaturedProductsLoading) {
                    return const ProductsGridSkeleton();
                  }

                  // Show loaded products
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                  }

                  // Show error with retry
                  if (state is FeaturedProductsError) {
                    final isOfflineError =
                        state.message.toLowerCase().contains('internet') ||
                        state.message.toLowerCase().contains('network') ||
                        state.message.toLowerCase().contains('connection');

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOfflineError
                                  ? Icons.wifi_off_rounded
                                  : Icons.error_outline,
                              size: 48,
                              color: isOfflineError
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _loadProducts,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2ED573),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
