import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/order/presentation/bloc/order_bloc.dart';
import 'package:mobile/features/order/presentation/bloc/order_event.dart';
import 'package:mobile/features/order/presentation/bloc/order_state.dart';
import 'package:mobile/features/product/domain/entities/address.dart';
import 'package:mobile/features/product/domain/entities/product.dart';

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

  final List<PaymentMethod> _paymentMethods = const [
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
      id: 'cash_on_delivery',
      name: 'Cash on Delivery',
      icon: Iconsax.wallet,
      color: Color(0xFF2ED573),
    ),
  ];

  double get _totalAmount => widget.product.price * widget.quantity;

  /// Safe way to get Variant ID
  String get _variantId {
    if (widget.product.variants == null || widget.product.variants.isEmpty) {
      return '';
    }

    try {
      final variant = widget.product.variants.firstWhere((v) {
        final colorMatch =
            widget.selectedColor == null || v.colorName == widget.selectedColor;
        final sizeMatch =
            widget.selectedSize == null || v.sizeName == widget.selectedSize;
        return colorMatch && sizeMatch;
      }, orElse: () => widget.product.variants.first);
      return variant.id;
    } catch (e) {
      return widget.product.variants.first.id;
    }
  }

  Map<String, dynamic> get _orderData {
    return {
      'items': [
        {'productVariantId': _variantId, 'quantity': widget.quantity},
      ],
      'shippingAddress': {
        'label': widget.address.label,
        'fullAddress': widget.address.fullAddress,
        'phoneNumber': widget.address.phoneNumber,
      },
      'paymentMethod': _selectedPaymentMethod,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderCreated) {
          if (_selectedPaymentMethod != null) {
            final phoneNumber = _selectedPaymentMethod == 'cash_on_delivery'
                ? null
                : widget.address.phoneNumber;

            context.read<OrderBloc>().add(
              ProcessPaymentEvent(
                orderId: state.order.id,
                paymentMethod: _selectedPaymentMethod!,
                phoneNumber: phoneNumber,
              ),
            );
          } else {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: Payment method missing')),
            );
          }
        } else if (state is PaymentProcessed) {
          setState(() => _isProcessing = false);
          final transactionId =
              state.paymentResult['transactionId'] ??
              state.paymentResult['orderNumber'] ??
              'N/A';
          _showSuccessDialog(transactionId);
        } else if (state is OrderError) {
          // 🚨 Show the new Failed Dialog instead of just a SnackBar
          setState(() => _isProcessing = false);
          _showFailedDialog(state.message);
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildOrderSummary(),
            _buildPaymentMethods(),
            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  void _processPayment() {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    if (widget.product.variants == null || widget.product.variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product has no available variants')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    context.read<OrderBloc>().add(CreateOrderEvent(_orderData));
  }

  void _showSuccessDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentSuccessDialog(
        orderId: transactionId,
        onContinue: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Close modal
          Navigator.pop(context); // Go back to product detail
        },
      ),
    );
  }

  // 🚨 NEW METHOD: Show the Payment Failed Dialog
  void _showFailedDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PaymentFailedDialog(
        errorMessage: errorMessage,
        onTryAgain: () {
          Navigator.pop(context); // Close dialog, user can click Pay Now again
        },
        onCancel: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Close payment modal
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
    );
  }

  Widget _buildOrderSummary() {
    return Container(
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
              Text(widget.product.name, style: const TextStyle(fontSize: 14)),
              Text(
                '\$${widget.product.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          if (widget.selectedColor != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Color: ${widget.selectedColor}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(),
              ],
            ),
          ],
          if (widget.selectedSize != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Size: ${widget.selectedSize}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(),
              ],
            ),
          ],
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
              Expanded(
                child: Text(
                  widget.address.fullAddress,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildPaymentMethods() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _paymentMethods.length,
        itemBuilder: (context, index) {
          final method = _paymentMethods[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedPaymentMethod = method.id),
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
    );
  }

  Widget _buildPayButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2ED573),
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
                  color: Colors.white,
                ),
              )
            : const Text(
                'Pay Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

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

// 🚨 NEW WIDGET: Payment Failed Dialog
class PaymentFailedDialog extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onTryAgain;
  final VoidCallback onCancel;

  const PaymentFailedDialog({
    super.key,
    required this.errorMessage,
    required this.onTryAgain,
    required this.onCancel,
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
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.close_circle,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Failed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTryAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ED573),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
