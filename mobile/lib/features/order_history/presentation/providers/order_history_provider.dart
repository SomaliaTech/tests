import 'package:flutter/material.dart';
import '../../models/order_model.dart';

enum OrderTab { products, internets }

class OrderHistoryProvider extends ChangeNotifier {
  OrderTab _currentTab = OrderTab.products;

  OrderTab get currentTab => _currentTab;

  List<Order> get currentOrders {
    return _currentTab == OrderTab.products ? productOrders : internetOrders;
  }

  bool get isEmpty => currentOrders.isEmpty;

  void setTab(OrderTab tab) {
    if (_currentTab != tab) {
      _currentTab = tab;
      notifyListeners();
    }
  }

  // Optional: Add methods for real API calls
  Future<void> refreshOrders() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    notifyListeners();
  }

  Future<void> trackOrder(String orderId, String? trackingNumber) async {
    if (trackingNumber != null) {
      // Implement tracking logic
      debugPrint('Tracking order $orderId: $trackingNumber');
    }
  }

  Future<void> viewOrderDetails(String orderId) async {
    // Implement order details navigation
    debugPrint('View order details: $orderId');
  }
}
