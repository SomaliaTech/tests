import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/common/widgets/shared/checkout_payment_modal.dart';
import 'package:mobile/core/network/api_client.dart';
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
      if (authState is Authenticated) {
        _userMarketId = authState.user.marketId;
      } else if (authState is OtpVerified) {
        _userMarketId = authState.user.marketId;
      } else if (authState is ProfileCompleted) {
        _userMarketId = authState.user.marketId;
      }

      final apiClient = sl<ApiClient>();
      final http.Response response = await apiClient.get('/markets');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final List<dynamic> marketsList;

        if (decodedData is List) {
          marketsList = decodedData;
        } else if (decodedData is Map && decodedData.containsKey('items')) {
          marketsList = decodedData['items'] as List<dynamic>;
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          marketsList = decodedData['data'] as List<dynamic>;
        } else {
          return;
        }

        if (mounted) {
          setState(() {
            _availableMarkets = marketsList.map((json) {
              final deliveryPriceStr =
                  json['deliveryPrice']?.toString() ?? '0.0';
              final parsedPrice = double.tryParse(deliveryPriceStr) ?? 0.0;
              final freeDeliveryQty = json['freeDeliveryMinQuantity'];

              return MarketEntity(
                id: json['id'] ?? '',
                name: json['name'] ?? '',
                slug: json['slug'] ?? '',
                city: json['city'],
                isActive: json['isActive'] ?? true,
                userCount: json['userCount'] ?? 0,
                deliveryPrice: parsedPrice,
                freeDeliveryMinQuantity: freeDeliveryQty is int
                    ? freeDeliveryQty
                    : (freeDeliveryQty != null
                          ? int.tryParse(freeDeliveryQty.toString())
                          : null),
                deliveryEstimationMinutes:
                    json['deliveryEstimationMinutes'] ?? 90,
                createdAt: json['createdAt'] != null
                    ? DateTime.parse(json['createdAt'])
                    : DateTime.now(),
                updatedAt: json['updatedAt'] != null
                    ? DateTime.parse(json['updatedAt'])
                    : DateTime.now(),
              );
            }).toList();
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
      final storageService = GetIt.instance<StorageService>();
      final isAdmin = await storageService.getIsAdmin();
      if (mounted) setState(() => _isAdmin = isAdmin);
    } catch (e) {
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
    if (changed) {
      setState(() {}); // Rebuild to show the chip
    }
  }

  void _toggleWishlist(Product product) {
    if (_isInWishlist) {
      context.read<WishlistBloc>().add(RemoveFromWishlistEvent(product.id));
      toastification.show(
        context: context,
        title: const Text('Removed from Wishlist'),
        description: Text('${product.name} removed from wishlist'),
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 2),
      );
      setState(() => _isInWishlist = false);
    } else {
      String variantId = '';
      if (product.variants.isNotEmpty) {
        final variant = product.variants.firstWhere(
          (v) => v.colorName == selectedColor && v.sizeName == selectedSize,
          orElse: () => product.variants.first,
        );
        variantId = variant.id;
      }
      final wishlistItem = WishlistItem(
        id: product.id,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        brand: product.brand,
        rating: product.rating,
        categoryId: product.categoryId,
        productVariantId: variantId,
      );
      context.read<WishlistBloc>().add(AddToWishlistEvent(wishlistItem));
      toastification.show(
        context: context,
        title: const Text('Added to Wishlist'),
        description: Text('${product.name} added to wishlist'),
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 2),
      );
      setState(() => _isInWishlist = true);
    }
  }

  bool _isProductInStock(Product product) {
    if (product.variants.isEmpty) return product.stock > 0;
    if (selectedColor != null || selectedSize != null) {
      try {
        final variant = product.variants.firstWhere(
          (v) => v.colorName == selectedColor && v.sizeName == selectedSize,
        );
        return (variant.stock ?? 0) > 0;
      } catch (_) {
        return product.variants.any((v) => (v.stock ?? 0) > 0);
      }
    }
    return product.variants.any((v) => (v.stock ?? 0) > 0) || product.stock > 0;
  }

  String _getSelectedVariantLabel(Product product) {
    if (product.variants.isEmpty) return '';
    if (selectedColor != null || selectedSize != null) {
      return '${selectedColor ?? ''} ${selectedSize ?? ''}'.trim();
    }
    return '';
  }

  void _addToCart(Product product) {
    ProductVariant? variant;
    int availableStock = product.stock;
    double price = product.price;
    bool autoSelected = false;

    if (product.variants.isNotEmpty) {
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

      try {
        variant = product.variants.firstWhere(
          (v) => v.colorName == selectedColor && v.sizeName == selectedSize,
        );
        availableStock = variant.stock ?? 0;
        price = variant.price ?? product.price;
      } catch (_) {
        if (product.variants.isNotEmpty) {
          variant = product.variants.first;
          availableStock = variant.stock ?? 0;
          price = variant.price ?? product.price;
          selectedColor = variant.colorName;
          selectedSize = variant.sizeName;
          autoSelected = true;
        }
      }

      if (autoSelected) {
        toastification.show(
          context: context,
          title: const Text('Auto-Selected'),
          description: Text(
            'Selected: ${variant?.colorName ?? selectedColor} ${variant?.sizeName ?? selectedSize}',
          ),
          type: ToastificationType.info,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    }

    if (availableStock <= 0) {
      toastification.show(
        context: context,
        title: const Text('Out of Stock'),
        description: Text(
          variant != null
              ? '${product.name} (${variant.colorName} ${variant.sizeName}) is out of stock'
              : '${product.name} is currently out of stock',
        ),
        type: ToastificationType.warning,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }

    if (quantity > availableStock) {
      toastification.show(
        context: context,
        title: const Text('Insufficient Stock'),
        description: Text('Only $availableStock available'),
        type: ToastificationType.warning,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }

    final cartItem = CartItem(
      id: variant?.id ?? product.id,
      productId: product.id,
      productVariantId: variant?.id ?? '',
      name: product.name,
      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
      price: price,
      quantity: quantity,
      maxStock: availableStock,
      inStock: availableStock > 0,
      color: variant?.colorName ?? selectedColor,
      size: variant?.sizeName ?? selectedSize,
    );

    context.read<CartBloc>().add(AddToCartEvent(cartItem));

    toastification.show(
      context: context,
      title: const Text('Added to Cart'),
      description: Text('${product.name} added to your cart'),
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _proceedToCheckout() async {
    if (_selectedAddress != null) {
      _showCheckoutScreen();
      return;
    }
    if (_isLoadingAddresses) {
      _showLoadingDialog();
      final startTime = DateTime.now();
      while (_isLoadingAddresses &&
          DateTime.now().difference(startTime).inSeconds < 3) {
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

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2ED573)),
      ),
    );
  }

  void _showAddressSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => AddressSelectionModal(
        onAddressSelected: (address) {
          Navigator.pop(modalContext);
          if (!mounted) return;
          setState(() => _selectedAddress = address);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showCheckoutScreen();
          });
        },
      ),
    );
  }

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

  void _navigateToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: MultiBlocListener(
        listeners: [
          BlocListener<AddressBloc, AddressState>(
            listener: (context, state) {
              if (state is AddressesLoaded) {
                setState(() => _isLoadingAddresses = false);
                if (_selectedAddress == null && state.addresses.isNotEmpty) {
                  final defaultAddress = state.addresses.firstWhere(
                    (addr) => addr.isDefault,
                    orElse: () => state.addresses.first,
                  );
                  setState(() => _selectedAddress = defaultAddress);
                }
              } else if (state is AddressError) {
                setState(() => _isLoadingAddresses = false);
              }
            },
          ),
          BlocListener<ProductBloc, ProductState>(
            listener: (context, state) {
              if (state is ProductDetailLoaded) {
                setState(() => _currentProduct = state.product);
                _autoSelectVariants(state.product); // ✅ Auto-select on load
              }
              if (state is ProductDetailError) {
                toastification.show(
                  context: context,
                  title: const Text('Error'),
                  description: Text(state.message),
                  type: ToastificationType.error,
                  style: ToastificationStyle.fillColored,
                  autoCloseDuration: const Duration(seconds: 3),
                );
              }
            },
          ),
          BlocListener<WishlistBloc, WishlistState>(
            listener: (context, state) {
              if (state is WishlistLoaded) {
                _isInWishlist = state.items.any(
                  (item) => item.id == widget.productId,
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
            if (product == null && _currentProduct != null) {
              product = _currentProduct;
            }

            final isLoading = state is ProductDetailLoading;

            if (state is ProductDetailError) {
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
                    Text(state.message, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<ProductBloc>().add(
                        GetProductByIdEvent(widget.productId),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ED573),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

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
                                onImageChanged: (index) =>
                                    setState(() => selectedImageIndex = index),
                              ),
                              ProductInfo(product: p),
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
                                  onOptionSelected: (color) =>
                                      setState(() => selectedColor = color),
                                  optionType: OptionType.color,
                                ),
                              if (p.sizes != null && p.sizes.isNotEmpty)
                                SelectionOptions(
                                  title: "Select Size:",
                                  options: p.sizes,
                                  selectedOption: selectedSize,
                                  onOptionSelected: (size) =>
                                      setState(() => selectedSize = size),
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
                      isInStock: _isProductInStock(p),
                      isInWishlist: _isInWishlist,
                      isAdmin: _isAdmin,
                      onFavoriteTap: () => _toggleWishlist(p),
                      onAddToCartTap: () => _addToCart(p),
                      onBuyNowTap: () => _proceedToCheckout(),
                      onChatTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const AdminChatBottomSheet(),
                        );
                      },
                    ),
                  ),
                ],
              );
            } else if (isLoading) {
              return const LoadingProductDetail();
            }

            return const LoadingProductDetail();
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AdminChatBottomSheet(),
            );
          },
          backgroundColor: const Color(0xFF2ED573),
          child: const Icon(Iconsax.message, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSelectedVariantChip(Product product) {
    final label = _getSelectedVariantLabel(product);
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2ED573).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2ED573).withValues(alpha: 0.3),
        ),
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
    final address = _selectedAddress!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2ED573), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2ED573).withValues(alpha: 0.1),
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
              color: const Color(0xFF2ED573).withValues(alpha: 0.1),
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
                  address.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address.fullAddress,
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
