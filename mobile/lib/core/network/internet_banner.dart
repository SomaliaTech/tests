// lib/core/common/widgets/internet_banner.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/services/connectivity_service.dart';

class InternetBanner extends StatefulWidget {
  const InternetBanner({super.key});

  @override
  State<InternetBanner> createState() => _InternetBannerState();
}

class _InternetBannerState extends State<InternetBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  bool _wasOffline = false;
  Timer? _recheckTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _recheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        final isOffline = connectivity.status == ConnectionStatus.offline;

        // Animate banner in/out
        if (isOffline && !_wasOffline) {
          _animationController.forward();
          _startRecheckTimer(connectivity);
        } else if (!isOffline && _wasOffline) {
          _animationController.reverse();
          _recheckTimer?.cancel();
        }
        _wasOffline = isOffline;

        // Don't render if not offline and not animating
        if (!isOffline && _animationController.isDismissed) {
          return const SizedBox.shrink();
        }

        // ✅ Use Positioned or wrap in a way that doesn't affect layout
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 1.0 + _slideAnimation.value,
                child: child,
              ),
            );
          },
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: double.infinity,
              height: 44, // Standard app bar height
              decoration: BoxDecoration(
                // Liquid glass effect
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.shade500.withOpacity(0.9),
                    Colors.red.shade700.withOpacity(0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: const ColorFilter.mode(
                    Colors.white10,
                    BlendMode.srcOver,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      // Glass shine
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                      // Bottom border
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.15),
                          width: 0.5,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Pulsing wifi icon
                            _PulsingIcon(),
                            const SizedBox(width: 10),
                            // Text
                            Flexible(
                              child: Text(
                                'No internet connection',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Retry button
                            _GlassButton(
                              onPressed: () => connectivity.manualRetry(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startRecheckTimer(ConnectivityService connectivity) {
    _recheckTimer?.cancel();
    _recheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      connectivity.checkNow();
    });
  }
}

// Pulsing wifi icon
class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        );
      },
    );
  }
}

// Glass-style retry button
class _GlassButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GlassButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                color: Colors.white.withOpacity(0.95),
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
