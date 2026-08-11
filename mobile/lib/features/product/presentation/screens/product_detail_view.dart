import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/common/widgets/shared/checkout_payment_modal.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/domain/entities/market_entity.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mobile/features/chat/presentation/widgets/admin_chat_bottom_sheet.dart';
import 'package:mobile/features/product/domain/entities/address.dart';
import 'package:mobile/features/product/domain/entities/product.dart';
import 'package:mobile/features/product/presentation/blocs/address_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/address_event.dart';
import 'package:mobile/features/product/presentation/blocs/address_state.dart';
import 'package:mobile/features/product/presentation/blocs/product_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/product_event.dart';
import 'package:mobile/features/product/presentation/blocs/product_state.dart';
import 'package:mobile/features/product/presentation/widgets/address/address_selection_modal.dart';
import 'package:mobile/features/product/presentation/widgets/home/selection_options.dart';
import 'package:mobile/features/product/presentation/widgets/loading/loading_product_detail.dart';
import 'package:mobile/features/product/presentation/widgets/product/bottom_action_bar.dart';
import 'package:mobile/features/product/presentation/widgets/product/description_tab.dart';
import 'package:mobile/features/product/presentation/widgets/product/image_carousel.dart';
import 'package:mobile/features/product/presentation/widgets/product/product_header.dart';
import 'package:mobile/features/product/presentation/widgets/product/product_info.dart';
import 'package:mobile/features/product/presentation/widgets/product/related_products.dart';
import 'package:toastification/toastification.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../../wishlist/presentation/bloc/wishlist_event.dart';
import '../../../wishlist/presentation/bloc/wishlist_state.dart';
import '../../../wishlist/domain/entities/wishlist_item.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/domain/entities/cart_item.dart';

class ProductDetailView extends StatefulWidget {
  final String productId;
  const ProductDetailView({super.key, required this.productId});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int selectedImageIndex = 0;
  String? selectedColor;
  String? selectedSize;
  int quantity = 1;
  Address? _selectedAddress;
  bool _isInWishlist = false;
  bool _isAdmin = false;
  bool _isLoadingAddresses = false;
  bool _wasOffline = false;

  Product? _currentProduct;
  List<MarketEntity> _availableMarkets = [];
  String? _userMarketId;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadMarketsAndUserMarket();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductBloc>().add(GetProductByIdEvent(widget.productId));
      _checkWishlistStatus();
      _loadAddresses();
    });
  }

  Future<void> _loadMarketsAndUserMarket() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated)
        _userMarketId = authState.user.marketId;
      else if (authState is OtpVerified)
        _userMarketId = authState.user.marketId;
      else if (authState is ProfileCompleted)
        _userMarketId = authState.user.marketId;

      final apiClient = sl<ApiClient>();
      final http.Response response = await apiClient.get('/markets');
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final List<dynamic> marketsList;
        if (decodedData is List)
          marketsList = decodedData;
        else if (decodedData is Map && decodedData.containsKey('items'))
          marketsList = decodedData['items'];
        else if (decodedData is Map && decodedData.containsKey('data'))
          marketsList = decodedData['data'];
        else
          return;

        if (mounted) {
          setState(() {
            _availableMarkets = marketsList
                .map(
                  (json) => MarketEntity(
                    id: json['id'] ?? '',
                    name: json['name'] ?? '',
                    slug: json['slug'] ?? '',
                    city: json['city'],
                    isActive: json['isActive'] ?? true,
                    userCount: json['userCount'] ?? 0,
                    deliveryPrice:
                        double.tryParse(
                          json['deliveryPrice']?.toString() ?? '0.0',
                        ) ??
                        0.0,
                    freeDeliveryMinQuantity:
                        json['freeDeliveryMinQuantity'] is int
                        ? json['freeDeliveryMinQuantity']
                        : (json['freeDeliveryMinQuantity'] != null
                              ? int.tryParse(
                                  json['freeDeliveryMinQuantity'].toString(),
                                )
                              : null),
                    deliveryEstimationMinutes:
                        json['deliveryEstimationMinutes'] ?? 90,
                    createdAt: json['createdAt'] != null
                        ? DateTime.parse(json['createdAt'])
                        : DateTime.now(),
                    updatedAt: json['updatedAt'] != null
                        ? DateTime.parse(json['updatedAt'])
                        : DateTime.now(),
                  ),
                )
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading markets: $e');
    }
  }

  void _loadAddresses() {
    setState(() => _isLoadingAddresses = true);
    context.read<AddressBloc>().add(LoadAddressesEvent());
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await GetIt.instance<StorageService>().getIsAdmin();
      if (mounted) setState(() => _isAdmin = isAdmin);
    } catch (_) {
      _isAdmin = false;
    }
  }

  void _checkWishlistStatus() {
    final state = context.read<WishlistBloc>().state;
    if (state is WishlistLoaded) {
      _isInWishlist = state.items.any((item) => item.id == widget.productId);
      setState(() {});
    }
  }

  void _autoSelectVariants(Product product) {
    if (product.variants.isEmpty) return;
    bool changed = false;
    if (selectedColor == null &&
        product.colors != null &&
        product.colors.isNotEmpty) {
      selectedColor = product.colors.first;
      changed = true;
    }
    if (selectedSize == null &&
        product.sizes != null &&
        product.sizes.isNotEmpty) {
      selectedSize = product.sizes.first;
      changed = true;
    }
    if (changed) setState(() {});
  }

  // ✅ HELPER: Get the currently selected variant
  // ✅ HELPER: Get the currently selected variant
  ProductVariant? _getSelectedVariant(Product product) {
    if (product.variants.isEmpty) return null;

    // ✅ FIX: If user cleared selection, return null to show base price
    if (selectedColor == null && selectedSize == null) {
      return null;
    }

    try {
      return product.variants.firstWhere((v) {
        final colorMatch =
            selectedColor == null || v.colorName == selectedColor;
        final sizeMatch = selectedSize == null || v.sizeName == selectedSize;
        return colorMatch && sizeMatch;
      });
    } catch (_) {
      // No exact match found for current partial selection
      return null;
    }
  }

  // ✅ HELPER: Get the dynamic price based on selected variant
  double _getCurrentPrice(Product product) {
    final variant = _getSelectedVariant(product);
    if (variant != null && variant.price != null && variant.price! > 0) {
      return variant.price!;
    }
    return product.price;
  }

  void _toggleWishlist(Product product) {
    final currentPrice = _getCurrentPrice(product);
    final variant = _getSelectedVariant(product);

    if (_isInWishlist) {
      context.read<WishlistBloc>().add(RemoveFromWishlistEvent(product.id));
      _showSuccessToast(
        'Removed from Wishlist',
        '${product.name} removed from wishlist',
      );
      setState(() => _isInWishlist = false);
    } else {
      context.read<WishlistBloc>().add(
        AddToWishlistEvent(
          WishlistItem(
            id: product.id,
            name: product.name,
            price: currentPrice, // ✅ USE DYNAMIC PRICE
            imageUrl: product.imageUrls.isNotEmpty
                ? product.imageUrls.first
                : '',
            brand: product.brand,
            rating: product.rating,
            categoryId: product.categoryId,
            productVariantId: variant?.id ?? '',
          ),
        ),
      );
      _showSuccessToast(
        'Added to Wishlist',
        '${product.name} added to wishlist',
      );
      setState(() => _isInWishlist = true);
    }
  }

  bool _isProductInStock(Product product) {
    if (product.variants.isEmpty) return product.stock > 0;

    final variant = _getSelectedVariant(product);
    if (variant != null) {
      return (variant.stock ?? 0) > 0;
    }

    return product.variants.any((v) => (v.stock ?? 0) > 0) || product.stock > 0;
  }

  String _getSelectedVariantLabel(Product product) => (product.variants.isEmpty)
      ? ''
      : '${selectedColor ?? ''} ${selectedSize ?? ''}'.trim();

  void _addToCart(Product product) {
    ProductVariant? variant = _getSelectedVariant(product);
    int availableStock = product.stock;
    double price = _getCurrentPrice(product);
    bool autoSelected = false;

    if (product.variants.isNotEmpty) {
      if (variant == null) {
        if (selectedColor == null &&
            product.colors != null &&
            product.colors.isNotEmpty) {
          selectedColor = product.colors.first;
          autoSelected = true;
        }
        if (selectedSize == null &&
            product.sizes != null &&
            product.sizes.isNotEmpty) {
          selectedSize = product.sizes.first;
          autoSelected = true;
        }

        if (autoSelected) {
          setState(() {});
          variant = _getSelectedVariant(product);
        } else {
          variant = product.variants.first;
          selectedColor = variant.colorName;
          selectedSize = variant.sizeName;
          autoSelected = true;
          setState(() {});
        }
      }

      availableStock = variant?.stock ?? 0;
      price = (variant?.price != null && variant!.price! > 0)
          ? variant.price!
          : product.price;

      if (autoSelected) {
        _showInfoToast(
          'Auto-Selected',
          'Selected: ${variant?.colorName ?? selectedColor} ${variant?.sizeName ?? selectedSize}',
        );
      }
    }

    if (availableStock <= 0) {
      _showWarningToast(
        'Out of Stock',
        variant != null
            ? '${product.name} (${variant.colorName} ${variant.sizeName}) is out of stock'
            : '${product.name} is currently out of stock',
      );
      return;
    }
    if (quantity > availableStock) {
      _showWarningToast('Insufficient Stock', 'Only $availableStock available');
      return;
    }

    context.read<CartBloc>().add(
      AddToCartEvent(
        CartItem(
          id: variant?.id ?? product.id,
          productId: product.id,
          productVariantId: variant?.id ?? '',
          name: product.name,
          imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
          price: price, // ✅ USE DYNAMIC PRICE
          quantity: quantity,
          maxStock: availableStock,
          inStock: availableStock > 0,
          color: variant?.colorName ?? selectedColor,
          size: variant?.sizeName ?? selectedSize,
        ),
      ),
    );
    _showSuccessToast('Added to Cart', '${product.name} added to your cart');
  }

  void _showSuccessToast(String t, String d) => toastification.show(
    context: context,
    title: Text(t),
    description: Text(d),
    type: ToastificationType.success,
    style: ToastificationStyle.fillColored,
    autoCloseDuration: const Duration(seconds: 2),
  );
  void _showWarningToast(String t, String d) => toastification.show(
    context: context,
    title: Text(t),
    description: Text(d),
    type: ToastificationType.warning,
    style: ToastificationStyle.fillColored,
    autoCloseDuration: const Duration(seconds: 2),
  );
  void _showInfoToast(String t, String d) => toastification.show(
    context: context,
    title: Text(t),
    description: Text(d),
    type: ToastificationType.info,
    style: ToastificationStyle.fillColored,
    autoCloseDuration: const Duration(seconds: 2),
  );

  void _proceedToCheckout() async {
    if (_availableMarkets.isEmpty) {
      _showLoadingDialog();
      await _loadMarketsAndUserMarket();
      if (mounted) Navigator.of(context).pop();
    }

    if (_selectedAddress != null) {
      _showCheckoutScreen();
      return;
    }

    if (_isLoadingAddresses) {
      _showLoadingDialog();
      final start = DateTime.now();
      while (_isLoadingAddresses &&
          DateTime.now().difference(start).inSeconds < 3) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }
      if (mounted) Navigator.of(context).pop();
      if (_selectedAddress != null) {
        _showCheckoutScreen();
        return;
      }
    }

    _showAddressSelection();
  }

  void _showAddressSelection() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AddressSelectionModal(
      availableMarkets: _availableMarkets,
      userMarketId: _userMarketId,
      product: _currentProduct,
      selectedColor: selectedColor,
      selectedSize: selectedSize,
      quantity: quantity,
      onAddressSelected: (a) {
        Navigator.pop(ctx);
        if (!mounted) return;
        setState(() => _selectedAddress = a);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showCheckoutScreen();
        });
      },
    ),
  );

  void _showLoadingDialog() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: Color(0xFF2ED573)),
    ),
  );

  void _showCheckoutScreen() {
    if (!mounted || _currentProduct == null || _selectedAddress == null) return;
    if (_availableMarkets.isEmpty) {
      _loadMarketsAndUserMarket().then((_) {
        if (mounted) _navigateToCheckout();
      });
      return;
    }
    _navigateToCheckout();
  }

  void _navigateToCheckout() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CheckoutScreen(
        product: _currentProduct!,
        selectedColor: selectedColor,
        selectedSize: selectedSize,
        quantity: quantity,
        availableMarkets: _availableMarkets,
        userMarketId: _userMarketId,
        savedAddress: _selectedAddress,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ConnectivityService>(
        builder: (context, connectivity, _) {
          final isOnline = connectivity.status == ConnectionStatus.online;
          if (isOnline && _wasOffline && _currentProduct == null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => context.read<ProductBloc>().add(
                GetProductByIdEvent(widget.productId),
              ),
            );
          }
          _wasOffline = !isOnline;

          return MultiBlocListener(
            listeners: [
              BlocListener<AddressBloc, AddressState>(
                listener: (context, state) {
                  if (state is AddressesLoaded) {
                    setState(() => _isLoadingAddresses = false);
                    if (_selectedAddress == null &&
                        state.addresses.isNotEmpty) {
                      _selectedAddress = state.addresses.firstWhere(
                        (a) => a.isDefault,
                        orElse: () => state.addresses.first,
                      );
                    }
                  } else if (state is AddressError)
                    setState(() => _isLoadingAddresses = false);
                },
              ),
              BlocListener<ProductBloc, ProductState>(
                listener: (context, state) {
                  if (state is ProductDetailLoaded) {
                    setState(() => _currentProduct = state.product);
                    _autoSelectVariants(state.product);
                  }
                },
              ),
              BlocListener<WishlistBloc, WishlistState>(
                listener: (context, state) {
                  if (state is WishlistLoaded) {
                    _isInWishlist = state.items.any(
                      (i) => i.id == widget.productId,
                    );
                    setState(() {});
                  }
                },
              ),
            ],
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                Product? product;
                if (state is ProductDetailLoaded) {
                  product = state.product;
                  _currentProduct = product;
                }
                if (product == null && _currentProduct != null)
                  product = _currentProduct;
                if (state is ProductDetailLoading && product == null)
                  return const LoadingProductDetail();
                if (state is ProductDetailError && product == null)
                  return _buildStyledErrorState(state.message);
                if (product != null) {
                  final p = product;
                  return Stack(
                    children: [
                      Column(
                        children: [
                          ProductHeader(productName: p.name),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ImageCarousel(
                                    images: p.imageUrls,
                                    onImageChanged: (i) =>
                                        setState(() => selectedImageIndex = i),
                                  ),
                                  // ✅ PASS DYNAMIC PRICE
                                  ProductInfo(
                                    product: p,
                                    currentPrice: _getCurrentPrice(p),
                                  ),
                                  const SizedBox(height: 8),
                                  if (p.variants.isNotEmpty &&
                                      (selectedColor != null ||
                                          selectedSize != null))
                                    _buildSelectedVariantChip(p),
                                  if (_selectedAddress != null)
                                    _buildAddressDisplay(),
                                  if (p.colors != null && p.colors.isNotEmpty)
                                    SelectionOptions(
                                      title: "Select Color:",
                                      options: p.colors,
                                      selectedOption: selectedColor,
                                      onOptionSelected: (c) =>
                                          setState(() => selectedColor = c),
                                      optionType: OptionType.color,
                                    ),
                                  if (p.sizes != null && p.sizes.isNotEmpty)
                                    SelectionOptions(
                                      title: "Select Size:",
                                      options: p.sizes,
                                      selectedOption: selectedSize,
                                      onOptionSelected: (s) =>
                                          setState(() => selectedSize = s),
                                      optionType: OptionType.size,
                                    ),
                                  DescriptionTab(
                                    description: p.description,
                                    features: p.features ?? [],
                                  ),
                                  RelatedProducts(
                                    categoryId: p.categoryId,
                                    currentProductId: p.id,
                                  ),
                                  const SizedBox(height: 120),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: BottomActionBar(
                          productName: p.name,
                          currentPrice: _getCurrentPrice(
                            p,
                          ), // ✅ PASS DYNAMIC PRICE
                          isInStock: _isProductInStock(p),
                          isInWishlist: _isInWishlist,
                          isAdmin: _isAdmin,
                          onFavoriteTap: () => _toggleWishlist(p),
                          onAddToCartTap: () => _addToCart(p),
                          onBuyNowTap: () => _proceedToCheckout(),
                          onChatTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const AdminChatBottomSheet(),
                          ),
                        ),
                      ),
                      if (state is ProductDetailLoading)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: _buildSyncingIndicator(),
                        ),
                    ],
                  );
                }
                return const LoadingProductDetail();
              },
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AdminChatBottomSheet(),
          ),
          backgroundColor: const Color(0xFF2ED573),
          child: const Icon(Iconsax.message, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStyledErrorState(String message) {
    final isOffline =
        message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('connection');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isOffline
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOffline ? Iconsax.wifi_square : Iconsax.warning_2,
                size: 56,
                color: isOffline ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isOffline
                  ? 'No Internet Connection'
                  : 'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (isOffline) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.info_circle,
                      size: 20,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Check your Wi-Fi or mobile data connection and try again.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.read<ProductBloc>().add(
                  GetProductByIdEvent(widget.productId),
                ),
                icon: const Icon(Iconsax.refresh, size: 20),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ED573),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Iconsax.arrow_left, size: 18),
              label: const Text('Go Back'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncingIndicator() => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF2ED573).withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Syncing...',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    ),
  );

  Widget _buildSelectedVariantChip(Product p) {
    final label = _getSelectedVariantLabel(p);
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2ED573).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2ED573).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.verify, size: 16, color: Color(0xFF2ED573)),
          const SizedBox(width: 6),
          Text(
            'Selected: $label',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2ED573),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() {
              selectedColor = null;
              selectedSize = null;
            }),
            child: const Icon(
              Iconsax.close_circle,
              size: 16,
              color: Color(0xFF2ED573),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressDisplay() {
    final a = _selectedAddress!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2ED573), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2ED573).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2ED573).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Iconsax.location,
              color: Color(0xFF2ED573),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.fullAddress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showAddressSelection,
            child: const Text(
              'Change',
              style: TextStyle(
                color: Color(0xFF2ED573),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
