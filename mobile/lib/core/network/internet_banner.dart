// lib/core/common/widgets/internet_banner.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/services/connectivity_service.dart';

class InternetBanner extends StatelessWidget {
  const InternetBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        final isOffline = connectivity.status == ConnectionStatus.offline;

        // Handle background recheck when offline
        if (isOffline) {
          // Use a post-frame callback to avoid rebuilding during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _TimerManager().startTimer(connectivity);
          });
        } else {
          // Cancel any existing timer
          _TimerManager().cancelTimer();
        }

        // No UI shown
        return const SizedBox.shrink();
      },
    );
  }
}

// Simple timer manager to handle the timer lifecycle
class _TimerManager {
  static final _TimerManager _instance = _TimerManager._internal();

  // ✅ Fixed: Added the instance getter
  static _TimerManager get instance => _instance;

  factory _TimerManager() => _instance;

  _TimerManager._internal();

  Timer? _timer;

  void startTimer(ConnectivityService connectivity) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      connectivity.checkNow();
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
