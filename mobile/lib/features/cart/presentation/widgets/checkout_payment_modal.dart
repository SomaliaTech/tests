import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_event.dart';
import '../../../order/presentation/bloc/order_bloc.dart';
import '../../../order/presentation/bloc/order_event.dart';
import '../../../order/presentation/bloc/order_state.dart';
import '../../../product/domain/entities/address.dart';
import '../../domain/entities/cart_item.dart';

class CheckoutPaymentModal extends StatefulWidget {
  final List<CartItem> cartItems;
  final Address address;
  final double totalAmount;
  final VoidCallback onOrderComplete;

  const CheckoutPaymentModal({
    super.key,
    required this.cartItems,
    required this.address,
    required this.totalAmount,
    required this.onOrderComplete,
  });

  @override
  State<CheckoutPaymentModal> createState() => _CheckoutPaymentModalState();
}

class _CheckoutPaymentModalState extends State<CheckoutPaymentModal> {
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
      id: 'cash_on_delivery',
      name: 'Cash on Delivery',
      icon: Iconsax.wallet,
      color: Color(0xFF2ED573),
    ),
  ];

  Map<String, dynamic> get _orderData {
    return {
      'items': widget.cartItems
          .map(
            (item) => {
              'productVariantId': item.productVariantId,
              'quantity': item.quantity,
            },
          )
          .toList(),
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
          final transactionId = state.paymentResult['transactionId'] ?? 'N/A';
          _showSuccessDialog(transactionId);
        } else if (state is OrderError) {
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

    setState(() => _isProcessing = true);
    context.read<OrderBloc>().add(CreateOrderEvent(_orderData));
  }

  void _showSuccessDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CheckoutSuccessDialog(
        orderId: transactionId,
        onContinue: () {
          // Close dialog
          Navigator.of(dialogContext).pop();

          // Dispatch cart order completed event to clear cache
          context.read<CartBloc>().add(CartOrderCompletedEvent());

          // Close modal
          Navigator.of(context).pop();

          // Call callback
          widget.onOrderComplete();
        },
      ),
    );
  }

  void _showFailedDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CheckoutFailedDialog(
        errorMessage: errorMessage,
        onTryAgain: () {
          Navigator.pop(context); // Close dialog
        },
        onCancel: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Close modal
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
          ...widget.cartItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} x ${item.quantity}',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '\$${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
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
                '\$${widget.totalAmount.toStringAsFixed(2)}',
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
                'Place Order',
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

class CheckoutSuccessDialog extends StatelessWidget {
  final String orderId;
  final VoidCallback onContinue;

  const CheckoutSuccessDialog({
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
              'Order Placed Successfully!',
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

class CheckoutFailedDialog extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onTryAgain;
  final VoidCallback onCancel;

  const CheckoutFailedDialog({
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
              'Order Failed',
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
