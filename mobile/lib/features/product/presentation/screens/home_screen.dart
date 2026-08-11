import 'package:flutter/material.dart';
import 'package:mobile/features/product/presentation/widgets/home/latest_products_section.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/features/product/presentation/screens/search_results_screen.dart';

// BLoC imports
import '../blocs/product_bloc.dart';
import '../blocs/product_event.dart';
import '../blocs/banner/banner_bloc.dart'; // ✅ Added
import '../blocs/banner/banner_event.dart'; // ✅ Added

// Widget imports
import '../widgets/home/header.dart';
import '../widgets/home/banners_carousel.dart'; // ✅ Added
import '../widgets/home/categories_section.dart';
import '../widgets/home/hot_deals_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductBloc>().add(const GetFeaturedProductsEvent());
      context.read<BannerBloc>().add(
        const LoadBannersEvent(),
      ); // ✅ Added: Load banners
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ConnectivityService>(
        builder: (context, connectivity, _) {
          final isOnline = connectivity.status == ConnectionStatus.online;

          // Auto-refresh when internet comes back
          if (isOnline && _wasOffline) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<ProductBloc>().add(
                const GetFeaturedProductsEvent(forceRefresh: true),
              );
              context.read<BannerBloc>().add(
                const LoadBannersEvent(),
              ); // ✅ Added: Refresh banners too
            });
          }
          _wasOffline = !isOnline;

          return Column(
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
                    BannersCarousel(),
                    SizedBox(height: 16),
                    CategoriesSection(),
                    SizedBox(height: 16),
                    HotDealsSection(),
                    SizedBox(height: 16),
                    LatestProductsSection(), // ✅ Added here
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
