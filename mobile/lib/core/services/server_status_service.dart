// lib/core/services/server_status_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

class ServerStatusService {
  static final ServerStatusService _instance = ServerStatusService._internal();
  factory ServerStatusService() => _instance;
  ServerStatusService._internal();

  bool _isServerDown = false;

  /// Stream to notify UI about server status
  final _serverStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onServerStatusChange => _serverStatusController.stream;

  bool get isServerDown => _isServerDown;

  void markServerDown() {
    if (!_isServerDown) {
      _isServerDown = true;
      _serverStatusController.add(true);
      if (kDebugMode)
        debugPrint('🔴 Server marked as DOWN'); // ✅ Use print instead
    }
  }

  void markServerUp() {
    if (_isServerDown) {
      _isServerDown = false;
      _serverStatusController.add(false);
      if (kDebugMode)
        debugPrint('🟢 Server marked as UP'); // ✅ Use print instead
    }
  }
}
