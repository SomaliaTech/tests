// lib/core/services/connectivity_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

enum ConnectionStatus { online, offline, checking }

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  ConnectionStatus _status = ConnectionStatus.checking;
  bool _isInitialCheck = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicTimer;

  // ✅ Add a stream controller for connectivity changes
  final _connectivityStreamController =
      StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get onConnectivityChange =>
      _connectivityStreamController.stream;

  ConnectionStatus get status => _status;
  bool get isInitialCheck => _isInitialCheck;

  void initialize() {
    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _checkConnection();
    });

    // Periodic check every 10 seconds
    _periodicTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnection();
    });

    // Initial check
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      // First check connectivity
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      if (!hasConnection) {
        _updateStatus(ConnectionStatus.offline);
        return;
      }

      // Verify actual internet access with a quick ping
      try {
        final response = await http
            .get(Uri.parse('https://www.google.com'))
            .timeout(const Duration(seconds: 3));
        _updateStatus(
          response.statusCode == 200
              ? ConnectionStatus.online
              : ConnectionStatus.offline,
        );
      } catch (e) {
        _updateStatus(ConnectionStatus.offline);
      }
    } catch (e) {
      _updateStatus(ConnectionStatus.offline);
    }
  }

  void _updateStatus(ConnectionStatus newStatus) {
    if (_status != newStatus || _isInitialCheck) {
      final oldStatus = _status;
      _status = newStatus;
      _isInitialCheck = false;

      // ✅ Notify both listeners and stream
      notifyListeners();
      _connectivityStreamController.add(newStatus);

      debugPrint('🔌 Connectivity status changed: $oldStatus -> $newStatus');
    }
  }

  Future<void> manualRetry() async {
    _status = ConnectionStatus.checking;
    notifyListeners();
    await _checkConnection();
  }

  Future<void> checkNow() async {
    await _checkConnection();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _periodicTimer?.cancel();
    _connectivityStreamController.close();
    super.dispose();
  }
}
