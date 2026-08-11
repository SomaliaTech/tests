// lib/features/product/presentation/widgets/home/animated_carousel.dart

import 'dart:async';
import 'package:flutter/material.dart';

class CarouselItem {
  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? buttonText;
  final Color? backgroundColor;
  final LinearGradient? backgroundGradient;
  final Widget? customBadge;
  final VoidCallback? onTap;

  const CarouselItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.backgroundColor,
    this.backgroundGradient,
    this.customBadge,
    this.onTap,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarouselItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => id.hashCode ^ imageUrl.hashCode;
}

class AnimatedCarousel extends StatefulWidget {
  final List<CarouselItem> items;
  final double height;
  final Duration autoPlayInterval;
  final bool showIndicators;
  final bool showArrows;

  const AnimatedCarousel({
    super.key,
    required this.items,
    this.height = 200,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.showIndicators = true,
    this.showArrows = false,
  });

  @override
  State<AnimatedCarousel> createState() => _AnimatedCarouselState();
}

class _AnimatedCarouselState extends State<AnimatedCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(AnimatedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only restart if items actually changed
    final oldIds = oldWidget.items.map((e) => e.id).toList();
    final newIds = widget.items.map((e) => e.id).toList();

    if (!_listEquals(oldIds, newIds)) {
      if (_currentPage >= widget.items.length) {
        _currentPage = 0;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      }
      _restartAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _startAutoPlay() {
    _stopAutoPlay();
    if (widget.items.length <= 1) return;

    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (mounted && !_isUserInteracting && widget.items.length > 1) {
        _goToNextPage();
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _restartAutoPlay() {
    _stopAutoPlay();
    _startAutoPlay();
  }

  void _goToNextPage() {
    if (!_pageController.hasClients || widget.items.isEmpty) return;
    final nextPage = (_currentPage + 1) % widget.items.length;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _goToPage(int index) {
    if (!_pageController.hasClients || index >= widget.items.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ BUILD CHILDREN ONCE AND KEEP THEM
    final children = widget.items.map((item) {
      return _buildCarouselItem(item);
    }).toList();

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isUserInteracting = true;
              } else if (notification is ScrollEndNotification) {
                _isUserInteracting = false;
                _restartAutoPlay();
              }
              return false;
            },
            // ✅ USE PageView with fixed children list (NOT PageView.builder)
            // This preserves widget state!
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: children,
            ),
          ),

          // Navigation Arrows
          if (widget.showArrows && widget.items.length > 1) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _isUserInteracting = true;
                      final prevPage = _currentPage == 0
                          ? widget.items.length - 1
                          : _currentPage - 1;
                      _goToPage(prevPage);
                      _isUserInteracting = false;
                      _restartAutoPlay();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _isUserInteracting = true;
                      final nextPage = (_currentPage + 1) % widget.items.length;
                      _goToPage(nextPage);
                      _isUserInteracting = false;
                      _restartAutoPlay();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Page Indicators
          if (widget.showIndicators && widget.items.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.items.length,
                  (index) => _buildIndicator(index),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCarouselItem(CarouselItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: item.backgroundGradient,
          color: item.backgroundColor ?? Colors.grey[300],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: item.backgroundColor ?? Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.white54,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: item.backgroundColor ?? Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.75),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              if (item.customBadge != null)
                Positioned(top: 12, right: 12, child: item.customBadge!),
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                          color: Colors
                              .white, // ✅ Changed from white70 to pure white for better contrast
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                        maxLines:
                            2, // ✅ FIXED: Changed from 1 to 2 so it wraps properly
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.buttonText != null &&
                        item.buttonText!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          item.buttonText!,
                          style: const TextStyle(
                            color: Color(0xFF2ED573),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = index == _currentPage;
    return GestureDetector(
      onTap: () {
        _isUserInteracting = true;
        _goToPage(index);
        _isUserInteracting = false;
        _restartAutoPlay();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 4)]
              : null,
        ),
      ),
    );
  }
}
