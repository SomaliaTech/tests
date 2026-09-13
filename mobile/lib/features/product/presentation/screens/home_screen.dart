import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/features/product/presentation/screens/search_results_screen.dart';

// BLoC imports
import '../blocs/product_bloc.dart';
import '../blocs/product_event.dart';
import '../blocs/banner/banner_bloc.dart';
import '../blocs/banner/banner_event.dart';

// Widget imports
import '../widgets/home/header.dart';
import '../widgets/home/banners_carousel.dart';
import '../widgets/home/categories_section.dart';
import '../widgets/home/hot_deals_section.dart';
import 'package:mobile/features/product/presentation/widgets/home/latest_products_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ConnectivityService? _connectivityService;
  bool _wasOffline = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllData(forceRefresh: false);
      _connectivityService = context.read<ConnectivityService>();
      _connectivityService!.addListener(_onConnectivityChanged);
      _wasOffline = _connectivityService!.status != ConnectionStatus.online;
    });
  }

  void _fetchAllData({required bool forceRefresh}) {
    context.read<ProductBloc>().add(
      GetFeaturedProductsEvent(forceRefresh: forceRefresh),
    );
    context.read<ProductBloc>().add(
      GetLatestProductsEvent(forceRefresh: forceRefresh),
    );
    context.read<BannerBloc>().add(const LoadBannersEvent());
  }

  void _onConnectivityChanged() {
    final isOnline = _connectivityService?.status == ConnectionStatus.online;
    if (isOnline && _wasOffline) {
      _fetchAllData(forceRefresh: true);
    }
    _wasOffline = !isOnline;
  }

  @override
  void dispose() {
    _connectivityService?.removeListener(_onConnectivityChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Header(
            searchController: _searchController,
            onSearch: (query) async {
              if (query.trim().isEmpty) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SearchResultsScreen(initialQuery: query.trim()),
                ),
              );
              // Clear the header search bar after returning from search
              if (mounted) {
                _searchController.clear();
                setState(() {});
              }
            },
          ),
          const BannersCarousel(),
          const SizedBox(height: 16),
          const CategoriesSection(),
          const SizedBox(height: 16),
          const HotDealsSection(),
          const SizedBox(height: 16),
          const LatestProductsSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
