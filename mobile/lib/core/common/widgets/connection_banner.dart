// lib/core/common/widgets/connection_banner.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ConnectionBanner extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ConnectionBanner({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12,
          left: 16,
          right: 16,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
        ),
        child: SafeArea(
          child: Row(
            children: [
              const Icon(Iconsax.wifi, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message ?? 'Connecting...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onRetry != null)
                GestureDetector(
                  onTap: onRetry,
                  child: const Icon(
                    Iconsax.refresh,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
