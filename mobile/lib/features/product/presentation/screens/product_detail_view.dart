import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/product/presentation/models/product_model.dart';
import 'package:mobile/features/product/presentation/screens/product_detail_screen.dart';
import 'package:mobile/features/product/presentation/widgets/product/bottom_action_bar.dart';
import 'package:mobile/features/product/presentation/widgets/product/description_tab.dart';
import 'package:mobile/features/product/presentation/widgets/product/image_carousel.dart';
import 'package:mobile/features/product/presentation/widgets/product/product_header.dart';
import 'package:mobile/features/product/presentation/widgets/product/product_info.dart';
import 'package:mobile/features/product/presentation/widgets/shared/related_products.dart';
import 'package:mobile/features/product/presentation/widgets/home/selection_options.dart';
import 'package:mobile/features/product/presentation/widgets/address/address_selection_modal.dart';

class ProductDetailView extends StatefulWidget {
  final String productId;

  const ProductDetailView({super.key, required this.productId});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  late Product product;
  int selectedImageIndex = 0;
  String? selectedColor;
  String? selectedSize;
  int quantity = 1;
  Address? _selectedAddress;

  @override
  void initState() {
    super.initState();
    // Get product data
    product = products[widget.productId] ?? products["1"]!;
  }

  void _showAddressSelection() {
    print('Showing address selection modal');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressSelectionModal(
        onAddressSelected: (address) {
          print('Address selected: ${address.label} - ${address.fullAddress}');
          setState(() {
            _selectedAddress = address;
          });
          // Small delay to ensure setState completes
          Future.delayed(const Duration(milliseconds: 100), () {
            _proceedToPayment(address);
          });
        },
      ),
    );
  }

  void _proceedToPayment(Address address) {
    print('Proceeding to payment for address: ${address.label}');
    _showPaymentOptions(address);
  }

  void _showPaymentOptions(Address address) {
    print('Showing payment options modal for address: ${address.label}');
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
    final relatedProductsList = relatedProducts
        .where((p) => p.category == product.category)
        .take(4)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              ProductHeader(productName: product.name),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Carousel
                      ImageCarousel(
                        images: product.images,
                        onImageChanged: (index) {
                          setState(() {
                            selectedImageIndex = index;
                          });
                        },
                      ),

                      // Product Info Section
                      ProductInfo(product: product),

                      const SizedBox(height: 8),

                      // Selection Options
                      if (product.colors != null && product.colors!.isNotEmpty)
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

                      if (product.sizes != null && product.sizes!.isNotEmpty)
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

                      // Selected Address Display (if any)
                      if (_selectedAddress != null)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2ED573,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2ED573)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.location,
                                color: Color(0xFF2ED573),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Delivery Address',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2ED573),
                                      ),
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
                        ),

                      // Description Tab
                      DescriptionTab(
                        description: product.description,
                        features: product.features,
                      ),

                      // Related Products
                      RelatedProducts(
                        products: relatedProductsList,
                        onProductTap: (productId) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(productId: productId),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomActionBar(
              onFavoriteTap: () {
                // Handle favorite
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Added to favorites")),
                );
              },
              onBuyNowTap: () {
                if (_selectedAddress == null) {
                  _showAddressSelection();
                } else {
                  _showPaymentOptions(_selectedAddress!);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Payment Options Modal
class PaymentOptionsModal extends StatefulWidget {
  final Product product;
  final Address address;
  final String? selectedColor;
  final String? selectedSize;
  final int quantity;

  const PaymentOptionsModal({
    super.key,
    required this.product,
    required this.address,
    this.selectedColor,
    this.selectedSize,
    required this.quantity,
  });

  @override
  State<PaymentOptionsModal> createState() => _PaymentOptionsModalState();
}

class _PaymentOptionsModalState extends State<PaymentOptionsModal> {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: 'evc_plus',
      name: 'EVC Plus',
      icon: Iconsax.mobile,
      color: Color(0xFF2ED573),
    ),
    PaymentMethod(
      id: 'zaad',
      name: 'Zaad',
      icon: Iconsax.money,
      color: Color(0xFF2ED573),
    ),
    PaymentMethod(
      id: 'jeep_hurmuud',
      name: 'Jeep',
      icon: Iconsax.wallet,
      color: Color(0xFF2ED573),
    ),
  ];

  void _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
    });

    // Show success dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PaymentSuccessDialog(
          orderId: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
          onContinue: () {
            Navigator.pop(context); // Close success dialog
            Navigator.pop(context); // Close payment modal
            Navigator.pop(context); // Go back to product detail
          },
        );
      },
    );
  }

  double get _totalAmount {
    return widget.product.price * widget.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Payment Method',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Order Summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '\$${widget.product.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                if (widget.selectedColor != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Color: ${widget.selectedColor}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(),
                      ],
                    ),
                  ),
                if (widget.selectedSize != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Size: ${widget.selectedSize}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(),
                      ],
                    ),
                  ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quantity: ${widget.quantity}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '\$${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery', style: TextStyle(fontSize: 14)),
                    Text(
                      '${widget.address.fullAddress}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2ED573),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Payment Methods
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method.id;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedPaymentMethod == method.id
                            ? const Color(0xFF2ED573)
                            : const Color(0xFFEEEEEE),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(method.icon, color: method.color, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            method.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_selectedPaymentMethod == method.id)
                          const Icon(
                            Iconsax.tick_circle,
                            color: Color(0xFF2ED573),
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Pay Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ED573),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Payment Method Model
class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

// Payment Success Dialog
class PaymentSuccessDialog extends StatelessWidget {
  final String orderId;
  final VoidCallback onContinue;

  const PaymentSuccessDialog({
    super.key,
    required this.orderId,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF2ED573),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.tick_circle,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Order #$orderId',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your order has been confirmed',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ED573),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
