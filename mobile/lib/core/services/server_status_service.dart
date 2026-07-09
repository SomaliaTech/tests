// lib/core/services/server_status_service.dart
import 'dart:async';

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
      print('🔴 Server marked as DOWN'); // ✅ Use print instead
    }
  }

  void markServerUp() {
    if (_isServerDown) {
      _isServerDown = false;
      _serverStatusController.add(false);
      print('🟢 Server marked as UP'); // ✅ Use print instead
    }
  }
}
