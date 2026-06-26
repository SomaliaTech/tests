import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/cart/presentation/widgets/checkout_payment_modal.dart';
import 'package:mobile/features/product/presentation/blocs/address_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/address_event.dart';
import 'package:mobile/features/product/presentation/blocs/address_state.dart';
import '../../../product/domain/entities/address.dart';

import '../../../product/presentation/widgets/address/address_selection_modal.dart';

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

  @override
  void initState() {
    super.initState();
    // ✅ Load addresses when cart view opens
    _loadAddresses();
  }

  void _loadAddresses() {
    context.read<AddressBloc>().add(LoadAddressesEvent());
  }

  void _proceedToCheckout() {
    if (_selectedAddress == null) {
      _showAddressSelection();
    } else {
      _showPaymentOptions();
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
            _showPaymentOptions();
          });
        },
      ),
    );
  }

  void _showPaymentOptions() {
    final state = context.read<CartBloc>().state;
    if (state is CartLoaded && _selectedAddress != null) {
      final totalAmount = state.total;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CheckoutPaymentModal(
          cartItems: state.items,
          address: _selectedAddress!,
          totalAmount: totalAmount,
        ),
      );
    }
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
          // ✅ Listen to address changes
          BlocListener<AddressBloc, AddressState>(
            listener: (context, state) {
              if (state is AddressesLoaded && !_addressesLoaded) {
                _addressesLoaded = true;
                // ✅ Auto-select default address
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

              return Column(
                children: [
                  // ✅ Show selected address info
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
                              onIncrement: () {
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
                            shippingFee: state.shippingFee,
                            discount: state.discount,
                            total: state.total,
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  BottomCheckoutBar(
                    itemCount: state.itemCount,
                    total: state.total,
                    isEnabled: state.isCheckoutEnabled,
                    onCheckout: _proceedToCheckout,
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
