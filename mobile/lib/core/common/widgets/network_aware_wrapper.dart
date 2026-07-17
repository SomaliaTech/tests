// lib/core/common/widgets/network_aware_wrapper.dart
import 'package:flutter/material.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/common/widgets/no_internet_screen.dart';
import 'package:mobile/core/common/widgets/connection_banner.dart';
import 'package:provider/provider.dart';

class NetworkAwareWrapper extends StatelessWidget {
  final Widget child;
  final bool showBanner;

  const NetworkAwareWrapper({
    super.key,
    required this.child,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        // During initial check, show a loading overlay on the child
        if (connectivity.isInitialCheck) {
          return Stack(
            children: [
              child,
              // Semi-transparent overlay
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Checking connection...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // Completely offline - show full screen
        if (connectivity.status == ConnectionStatus.offline) {
          return NoInternetScreen(onRetry: () => connectivity.manualRetry());
        }

        // Online - show app normally
        return child;
      },
    );
  }
}
