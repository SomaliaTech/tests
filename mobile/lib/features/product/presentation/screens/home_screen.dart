import 'package:flutter/material.dart';
import 'package:mobile/features/product/presentation/widgets/home/latest_products_section.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/services/connectivity_service.dart';

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
  ConnectivityService? _connectivityService;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Load initial data
      _fetchAllData(forceRefresh: false);

      // 2. Setup reliable connectivity listener
      _connectivityService = context.read<ConnectivityService>();
      _connectivityService!.addListener(_onConnectivityChanged);

      // 3. Set initial tracker based on current status
      _wasOffline = _connectivityService!.status != ConnectionStatus.online;
    });
  }

  // Helper to refresh ALL necessary blocs
  void _fetchAllData({required bool forceRefresh}) {
    context.read<ProductBloc>().add(
      GetFeaturedProductsEvent(forceRefresh: forceRefresh),
    );
    context.read<ProductBloc>().add(
      GetLatestProductsEvent(forceRefresh: forceRefresh),
    ); // ✅ Added Latest
    context.read<BannerBloc>().add(const LoadBannersEvent());

    // If you have a CategoryBloc, add it here too:
    // context.read<CategoryBloc>().add(GetCategoriesEvent(forceRefresh: forceRefresh));
  }

  void _onConnectivityChanged() {
    final isOnline = _connectivityService?.status == ConnectionStatus.online;

    // 🚀 If we just came back online from an offline state
    if (isOnline && _wasOffline) {
      _fetchAllData(forceRefresh: true);

      // Optional: Show a quick UI feedback so the user knows it's refreshing
    }

    // Update the tracker for the next network change
    _wasOffline = !isOnline;
  }

  @override
  void dispose() {
    // 🧹 Always remove listeners to prevent memory leaks
    _connectivityService?.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // You no longer need the Consumer wrapper just for the refresh logic!
    // (Unless you are using it to show an "Offline Banner" at the top of the UI)
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: const [
          Header(), // Pass your search callback here
          BannersCarousel(),
          SizedBox(height: 16),
          CategoriesSection(),
          SizedBox(height: 16),
          HotDealsSection(),
          SizedBox(height: 16),
          LatestProductsSection(),
          SizedBox(height: 100),
        ],
      ),
    );
  }
}
