// lib/core/services/connectivity_service.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/constants/api_constants.dart';

enum ConnectionStatus { online, offline, checking }

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;

  ConnectionStatus _status = ConnectionStatus.checking;
  ConnectionStatus get status => _status;

  bool _isInitialCheck = true;
  bool get isInitialCheck => _isInitialCheck;

  Timer? _periodicCheckTimer;
  Timer? _debounceTimer;

  static const Duration _debounceDuration = Duration(seconds: 2);
  static const Duration _periodicCheckInterval = Duration(seconds: 15);

  void initialize() {
    _checkActualConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(_periodicCheckInterval, (_) {
      _checkActualConnectivity();
    });
  }

  Future<void> _checkActualConnectivity() async {
    try {
      // First check if device has network interface
      final results = await _connectivity.checkConnectivity();
      final hasNetworkInterface = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      if (!hasNetworkInterface) {
        _updateStatus(ConnectionStatus.offline);
        return;
      }

      // Then actually try to reach YOUR server
      final canReachServer = await _canReachServer();

      if (canReachServer) {
        _updateStatus(ConnectionStatus.online);
      } else {
        _updateStatus(ConnectionStatus.offline);
      }
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      _updateStatus(ConnectionStatus.offline);
    }

    if (_isInitialCheck) {
      _isInitialCheck = false;
      notifyListeners();
    }
  }

  Future<bool> _canReachServer() async {
    try {
      // Parse your server URL to get host and port
      final uri = Uri.parse(ApiConstants.baseUrl);
      final host = uri.host;
      final port = uri.port;

      // Try to connect to your server's socket
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } on SocketException catch (e) {
      debugPrint('Server unreachable: $e');
      return false;
    } on TimeoutException catch (_) {
      debugPrint('Server connection timeout');
      return false;
    } catch (e) {
      debugPrint('Server check error: $e');
      return false;
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _checkActualConnectivity();
    });
  }

  void _updateStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
      debugPrint('🔌 Connectivity status changed: $newStatus');
    }
  }

  Future<bool> hasConnection() async {
    return _status == ConnectionStatus.online;
  }

  void manualRetry() {
    _status = ConnectionStatus.checking;
    _isInitialCheck = true;
    notifyListeners();
    _checkActualConnectivity();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _debounceTimer?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }
}
