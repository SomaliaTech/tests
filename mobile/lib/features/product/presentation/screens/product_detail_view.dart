import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
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
import 'package:mobile/features/product/presentation/widgets/product/payment_options_modal.dart';
import 'package:mobile/features/product/presentation/widgets/product/product_header.dart';
import 'package:mobile/features/product/presentation/widgets/product/product_info.dart';
import 'package:mobile/features/product/presentation/widgets/product/related_products.dart';
import 'package:mobile/features/product/presentation/widgets/product/you_may_also_like.dart';
import 'package:toastification/toastification.dart';

// Order bloc import
import '../../../order/presentation/bloc/order_bloc.dart';

// Wishlist imports
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../../wishlist/presentation/bloc/wishlist_event.dart';
import '../../../wishlist/presentation/bloc/wishlist_state.dart';
import '../../../wishlist/domain/entities/wishlist_item.dart';

// Cart imports
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
  bool _addressesLoaded = false;

  // ✅ NEW: Store product locally so we don't need to read bloc state later
  Product? _currentProduct;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ProductBloc>().add(GetProductByIdEvent(widget.productId));
      _checkWishlistStatus();
      _loadAddresses();
    });
  }

  void _loadAddresses() {
    context.read<AddressBloc>().add(LoadAddressesEvent());
  }

  Future<void> _checkAdminStatus() async {
    try {
      final storageService = GetIt.instance<StorageService>();
      final isAdmin = await storageService.getIsAdmin();
      if (mounted) {
        setState(() => _isAdmin = isAdmin);
      }
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

  void _toggleWishlist(Product product) {
    if (_isInWishlist) {
      context.read<WishlistBloc>().add(RemoveFromWishlistEvent(product.id));
      toastification.show(
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
        title: const Text('Added to Wishlist'),
        description: Text('${product.name} added to wishlist'),
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 2),
      );
      setState(() => _isInWishlist = true);
    }
  }

  void _addToCart(Product product) {
    ProductVariant? variant;

    if (product.variants.isNotEmpty) {
      variant = product.variants.firstWhere(
        (v) => v.colorName == selectedColor && v.sizeName == selectedSize,
        orElse: () => product.variants.first,
      );
    }

    final cartItem = CartItem(
      id: variant?.id ?? product.id,
      productId: product.id,
      productVariantId: variant?.id ?? '',
      name: product.name,
      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
      price: variant?.price ?? product.price,
      quantity: quantity,
      maxStock: variant?.stock ?? product.stock,
      inStock: (variant?.stock ?? product.stock) > 0,
      color: variant?.colorName,
      size: variant?.sizeName,
    );

    context.read<CartBloc>().add(AddToCartEvent(cartItem));

    toastification.show(
      title: const Text('Added to Cart'),
      description: Text('${product.name} added to your cart'),
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _proceedToCheckout() {
    print('🔍 _proceedToCheckout called');
    print('📍 _selectedAddress: $_selectedAddress');
    print('📍 _currentProduct: ${_currentProduct?.name}');

    if (_selectedAddress == null) {
      print('📍 No address selected, showing address selection');
      _showAddressSelection();
    } else {
      print('📍 Address exists, showing payment options');
      _showPaymentOptions();
    }
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

          setState(() {
            _selectedAddress = address;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showPaymentOptions();
          });
        },
      ),
    );
  }

  // ✅ FIXED: Use locally stored product instead of reading bloc state
  void _showPaymentOptions() {
    print('🔍 _showPaymentOptions called');

    if (!mounted) {
      print('❌ Widget not mounted');
      return;
    }

    // ✅ Use locally stored product
    if (_currentProduct == null) {
      print('❌ No product stored locally');
      return;
    }

    if (_selectedAddress == null) {
      print('❌ No address selected');
      return;
    }

    print('✅ Showing payment modal with product: ${_currentProduct!.name}');

    final orderBloc = GetIt.instance<OrderBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocProvider.value(
        value: orderBloc,
        child: PaymentOptionsModal(
          product: _currentProduct!, // ✅ Use locally stored product
          address: _selectedAddress!,
          selectedColor: selectedColor,
          selectedSize: selectedSize,
          quantity: quantity,
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
              if (state is AddressesLoaded && !_addressesLoaded) {
                _addressesLoaded = true;
                if (state.addresses.isNotEmpty) {
                  final defaultAddress = state.addresses.firstWhere(
                    (addr) => addr.isDefault,
                    orElse: () => state.addresses.first,
                  );
                  setState(() {
                    _selectedAddress = defaultAddress;
                  });
                }
              }
            },
          ),
          BlocListener<ProductBloc, ProductState>(
            listener: (context, state) {
              // ✅ Only handle ProductDetailLoaded
              if (state is ProductDetailLoaded) {
                setState(() {
                  _currentProduct = state.product;
                });
              }

              if (state is ProductDetailError) {
                toastification.show(
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
            // ✅ Only handle ProductDetailLoaded - ignore other states
            Product? product;

            if (state is ProductDetailLoaded) {
              product = state.product;
              // ✅ Store it locally immediately
              _currentProduct = product;
            }

            // ✅ Fallback to locally stored product
            if (product == null && _currentProduct != null) {
              product = _currentProduct;
            }

            // ✅ Check for loading state
            final isLoading = state is ProductDetailLoading;

            // ✅ Check for error state
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
                      onPressed: () {
                        context.read<ProductBloc>().add(
                          GetProductByIdEvent(widget.productId),
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

            // ✅ Render product if available
            if (product != null) {
              return Stack(
                children: [
                  Column(
                    children: [
                      ProductHeader(productName: product.name),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ImageCarousel(
                                images: product.imageUrls,
                                onImageChanged: (index) {
                                  setState(() {
                                    selectedImageIndex = index;
                                  });
                                },
                              ),
                              ProductInfo(product: product),
                              const SizedBox(height: 8),
                              if (_selectedAddress != null)
                                _buildAddressDisplay(),
                              if (product.colors != null &&
                                  product.colors!.isNotEmpty)
                                SelectionOptions(
                                  title: "Select Color:",
                                  options: product.colors!,
                                  selectedOption: selectedColor,
                                  onOptionSelected: (color) {
                                    setState(() {
                                      selectedColor = color;
                                    });
                                  },
                                  optionType: OptionType.color,
                                ),
                              if (product.sizes != null &&
                                  product.sizes!.isNotEmpty)
                                SelectionOptions(
                                  title: "Select Size:",
                                  options: product.sizes!,
                                  selectedOption: selectedSize,
                                  onOptionSelected: (size) {
                                    setState(() {
                                      selectedSize = size;
                                    });
                                  },
                                  optionType: OptionType.size,
                                ),
                              DescriptionTab(
                                description: product.description,
                                features: product.features ?? [],
                              ),

                              RelatedProducts(
                                categoryId: product.categoryId,
                                currentProductId: product.id,
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
                      productName: product.name,
                      isInWishlist: _isInWishlist,
                      isAdmin: _isAdmin,
                      onFavoriteTap: () => _toggleWishlist(product!),
                      onAddToCartTap: () => _addToCart(product!),
                      onBuyNowTap: () {
                        _proceedToCheckout();
                      },
                    ),
                  ),
                ],
              );
            } else if (isLoading) {
              return const LoadingProductDetail();
            }

            // Default: show loading
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

  Widget _buildAddressDisplay() {
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
                  _selectedAddress!.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedAddress!.fullAddress,
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
