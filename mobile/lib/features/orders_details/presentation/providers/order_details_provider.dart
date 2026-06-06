import 'package:flutter/material.dart';
import '../../models/order_details_model.dart';

class OrderDetailsProvider extends ChangeNotifier {
  OrderDetails? _order;
  bool _isLoading = false;
  String? _error;

  OrderDetails? get order => _order;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasOrder => _order != null;

  void loadOrder(String orderId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mockOrderDetails.containsKey(orderId)) {
        _order = mockOrderDetails[orderId];
        _error = null;
      } else {
        _order = null;
        _error = 'Order not found';
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  void refreshOrder() {
    if (_order != null) {
      loadOrder(_order!.id);
    }
  }

  Future<void> reorder() async {
    // Implement reorder logic
    debugPrint('Reorder initiated for order: ${_order?.id}');
  }

  Future<void> shareOrder() async {
    if (_order != null) {
      // Implement share logic
      debugPrint('Sharing order: ${_order!.id}');
    }
  }

  Future<void> downloadInvoice() async {
    // Implement invoice download
    debugPrint('Downloading invoice for order: ${_order?.id}');
  }

  void navigateToTracking(BuildContext context) {
    if (_order != null && _order!.canTrack) {
      // Navigate to tracking screen
      debugPrint('Navigate to tracking for order: ${_order!.id}');
    }
  }
}
