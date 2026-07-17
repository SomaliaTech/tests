import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/common/widgets/shared/checkout_payment_modal.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/features/admin/domain/entities/market_entity.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mobile/features/cart/domain/entities/cart_item.dart';
import 'package:mobile/features/product/presentation/blocs/address_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/address_event.dart';
import 'package:mobile/features/product/presentation/blocs/address_state.dart';
import 'package:mobile/features/product/presentation/widgets/address/address_selection_modal.dart';
import '../../../product/domain/entities/address.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../widgets/bottom_checkout_bar.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/empty_cart_view.dart';
import '../widgets/price_summary.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  Address? _selectedAddress;
  bool _addressesLoaded = false;

  List<MarketEntity> _availableMarkets = [];
  String? _userMarketId;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadMarketsAndUserMarket();
  }

  void _loadAddresses() {
    context.read<AddressBloc>().add(LoadAddressesEvent());
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
      debugPrint('Error loading markets in cart: $e');
    }
  }

  void _proceedToCheckout() {
    if (_selectedAddress == null) {
      _showAddressSelection();
    } else {
      _showCheckoutScreen();
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
            if (mounted) _showCheckoutScreen();
          });
        },
      ),
    );
  }

  void _showCheckoutScreen() {
    final state = context.read<CartBloc>().state;
    if (state is CartLoaded && _selectedAddress != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen.fromCart(
            cartItems: state.items,
            availableMarkets: _availableMarkets,
            userMarketId: _userMarketId,
            savedAddress: _selectedAddress,
          ),
        ),
      );
    }
  }

  double get _dynamicShippingFee {
    if (_availableMarkets.isEmpty || _userMarketId == null) return 0.0;

    final userMarket = _availableMarkets.firstWhere(
      (m) => m.id == _userMarketId,
      orElse: () => _availableMarkets.first,
    );

    final state = context.read<CartBloc>().state;
    if (state is CartLoaded) {
      final totalItems = state.items.fold(
        0,
        (sum, item) => sum + item.quantity,
      );
      final minQty = userMarket.freeDeliveryMinQuantity;

      if (minQty != null && minQty > 0 && totalItems >= minQty) {
        return 0.0;
      }
    }

    return userMarket.deliveryPrice;
  }

  double get _dynamicTotal {
    final state = context.read<CartBloc>().state;
    if (state is CartLoaded) {
      return state.subtotal + _dynamicShippingFee - state.discount;
    }
    return 0;
  }

  // ✅ Check for stock issues - ignores unrealistic maxStock values
  List<CartItem> _getStockIssues(List<CartItem> items) {
    return items.where((item) {
      // Out of stock
      if (!item.inStock) {
        debugPrint('🔴 Stock issue: ${item.name} - out of stock');
        return true;
      }
      // Check if quantity exceeds real maxStock (not default 999)
      if (item.maxStock > 0 &&
          item.maxStock < 500 &&
          item.quantity > item.maxStock) {
        debugPrint(
          '🔴 Stock issue: ${item.name} - qty ${item.quantity} > max ${item.maxStock}',
        );
        return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.trash, color: Color(0xFFFF4757)),
            onPressed: () => _showClearCartDialog(context),
          ),
        ],
      ),
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
          BlocListener<CartBloc, CartState>(
            listener: (context, state) {
              if (state is CartOrderSuccess) {
                _showOrderSuccessDialog(context);
              } else if (state is CartError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is CartSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: const Color(0xFF2ED573),
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state is CartLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2ED573)),
              );
            }

            if (state is CartLoaded) {
              if (state.isCartEmpty) {
                return EmptyCartView(
                  onStartShopping: () => Navigator.pop(context),
                );
              }

              final stockIssues = _getStockIssues(state.items);
              final hasIssues = stockIssues.isNotEmpty;

              return Column(
                children: [
                  // ✅ Stock warning banner
                  if (hasIssues)
                    _buildStockWarningBanner(stockIssues, state.items),

                  if (_selectedAddress != null)
                    Container(
                      margin: const EdgeInsets.all(15),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2ED573),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2ED573,
                              ).withValues(alpha: 0.1),
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
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          ...state.items.map(
                            (item) => CartItemCard(
                              item: item,
                              showStockWarning:
                                  item.inStock == false ||
                                  (item.maxStock > 0 &&
                                      item.maxStock < 500 &&
                                      item.quantity > item.maxStock),
                              onIncrement: () {
                                if (item.quantity >= item.maxStock &&
                                    item.maxStock < 500) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Maximum stock (${item.maxStock}) reached',
                                      ),
                                      backgroundColor: Colors.orange,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                if (item.canIncrease) {
                                  context.read<CartBloc>().add(
                                    UpdateQuantityEvent(
                                      item.productVariantId,
                                      item.quantity + 1,
                                    ),
                                  );
                                }
                              },
                              onDecrement: () {
                                if (item.canDecrease) {
                                  context.read<CartBloc>().add(
                                    UpdateQuantityEvent(
                                      item.productVariantId,
                                      item.quantity - 1,
                                    ),
                                  );
                                }
                              },
                              onRemove: () {
                                _showRemoveItemDialog(
                                  context,
                                  item.productVariantId,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          PriceSummary(
                            subtotal: state.subtotal,
                            shippingFee: _dynamicShippingFee,
                            discount: state.discount,
                            total: _dynamicTotal,
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  BottomCheckoutBar(
                    itemCount: state.itemCount,
                    total: _dynamicTotal,
                    isEnabled: state.isCheckoutEnabled && !hasIssues,
                    onCheckout: hasIssues ? null : _proceedToCheckout,
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // ✅ Stock warning banner
  Widget _buildStockWarningBanner(
    List<CartItem> issues,
    List<CartItem> allItems,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 10, 15, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.warning_2, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Stock Issues Detected',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  for (final item in issues) {
                    context.read<CartBloc>().add(
                      RemoveItemEvent(item.productVariantId),
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All problematic items removed'),
                      backgroundColor: Color(0xFF2ED573),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Remove All',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...issues.map((item) {
            final isOutOfStock = !item.inStock;
            final exceedsStock =
                item.maxStock > 0 &&
                item.maxStock < 500 &&
                item.quantity > item.maxStock;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Product image
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey[200],
                    ),
                    child: item.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Iconsax.image,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Icon(
                            Iconsax.box_1,
                            size: 16,
                            color: Colors.grey,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isOutOfStock
                              ? '⚠️ Out of stock'
                              : '⚠️ Qty ${item.quantity} exceeds max stock (${item.maxStock})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Individual remove button
                  GestureDetector(
                    onTap: () {
                      context.read<CartBloc>().add(
                        RemoveItemEvent(item.productVariantId),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} removed'),
                          backgroundColor: const Color(0xFF2ED573),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Iconsax.trash,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            'Please remove or adjust these items before checkout.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Iconsax.tick_circle, color: Color(0xFF2ED573), size: 28),
            SizedBox(width: 10),
            Text('Order Successful!'),
          ],
        ),
        content: const Text(
          'Thank you for your purchase. Your order has been placed successfully.',
        ),
        actions: [
          Expanded(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<CartBloc>().add(ClearCartEvent());
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF2ED573),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continue Shopping',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveItemDialog(BuildContext context, String productVariantId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: const Text(
            'Are you sure you want to remove this item from cart?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  context.read<CartBloc>().add(
                    RemoveItemEvent(productVariantId),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF4757),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text('Remove all items from cart?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  context.read<CartBloc>().add(ClearCartEvent());
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF4757),
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
}
