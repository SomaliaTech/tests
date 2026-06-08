import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/product/domain/entities/address.dart';
import 'package:mobile/features/product/domain/entities/product.dart';
import 'package:mobile/features/product/presentation/blocs/product_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/product_event.dart';
import 'package:mobile/features/product/presentation/blocs/product_state.dart';
import 'package:mobile/features/product/presentation/widgets/address/address_selection_modal.dart';
import 'package:mobile/features/product/presentation/widgets/home/selection_options.dart';
import 'package:mobile/features/product/presentation/widgets/product/bottom_action_bar.dart';
import 'package:mobile/features/product/presentation/widgets/product/description_tab.dart';
import 'package:mobile/features/product/presentation/widgets/product/image_carousel.dart';
import 'package:mobile/features/product/presentation/widgets/product/payment_options_modal.dart';
import 'package:mobile/features/product/presentation/widgets/product/product_header.dart';
import 'package:mobile/features/product/presentation/widgets/product/product_info.dart';
import 'package:toastification/toastification.dart';

// Wishlist imports
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../../wishlist/presentation/bloc/wishlist_event.dart';
import '../../../wishlist/presentation/bloc/wishlist_state.dart';
import '../../../wishlist/domain/entities/wishlist_item.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(GetProductByIdEvent(widget.productId));
    _checkWishlistStatus();
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
      final wishlistItem = WishlistItem(
        id: product.id,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        brand: product.brand,
        rating: product.rating,
        categoryId: product.categoryId,
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

  void _showAddressSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressSelectionModal(
        onAddressSelected: (address) {
          setState(() {
            _selectedAddress = address;
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            _proceedToPayment(address);
          });
        },
      ),
    );
  }

  void _proceedToPayment(Address address) {
    final state = context.read<ProductBloc>().state;
    if (state is ProductDetailLoaded) {
      _showPaymentOptions(address, state.product);
    }
  }

  void _showPaymentOptions(Address address, product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentOptionsModal(
        product: product,
        address: address,
        selectedColor: selectedColor,
        selectedSize: selectedSize,
        quantity: quantity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: MultiBlocListener(
        listeners: [
          BlocListener<ProductBloc, ProductState>(
            listener: (context, state) {
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
          buildWhen: (previous, current) =>
              current is ProductDetailLoading ||
              current is ProductDetailLoaded ||
              current is ProductDetailError,
          builder: (context, state) {
            if (state is ProductDetailLoaded) {
              final product = state.product;
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
                              // Selection Options - Colors
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
                              // Selection Options - Sizes
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
                              // Selected Address Display
                              if (_selectedAddress != null)
                                _buildAddressDisplay(),
                              DescriptionTab(
                                description: product.description,
                                features: product.features ?? [],
                              ),
                              const SizedBox(height: 100),
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
                      onFavoriteTap: () => _toggleWishlist(product),
                      onBuyNowTap: () {
                        if (_selectedAddress == null) {
                          _showAddressSelection();
                        } else {
                          _proceedToPayment(_selectedAddress!);
                        }
                      },
                    ),
                  ),
                ],
              );
            } else if (state is ProductDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProductDetailError) {
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
                        context.read<ProductBloc>()
                          ..add(GetProductByIdEvent(widget.productId));
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
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildAddressDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2ED573).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2ED573)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.location, color: Color(0xFF2ED573), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(fontSize: 12, color: Color(0xFF2ED573)),
                ),
                Text(
                  _selectedAddress!.fullAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.edit, size: 18),
            onPressed: _showAddressSelection,
          ),
        ],
      ),
    );
  }
}
