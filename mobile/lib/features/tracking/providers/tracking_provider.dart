import 'package:flutter/material.dart';
import '../data/models/tracking_model.dart';

class TrackingProvider extends ChangeNotifier {
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
      if (mockOrders.containsKey(orderId)) {
        _order = mockOrders[orderId];
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

  void contactSupport() {
    debugPrint('Contact support tapped');
  }

  void trackOnMap() {
    debugPrint('Track on map tapped');
  }

  List<TrackingStep> getStepsInOrder() {
    if (_order == null) return [];
    // Return steps in chronological order (oldest first)
    return List.from(_order!.steps.reversed);
  }
}
