// lib/features/order/presentation/widgets/order_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/order/domain/entities/order_history.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrderCard extends StatelessWidget {
  final OrderHistory order;
  final VoidCallback onTrackPressed;
  final VoidCallback onDetailsPressed;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTrackPressed,
    required this.onDetailsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = order.status.color;
    final timeAgo = _getTimeAgo(order.createdAt);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onDetailsPressed();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            // Top Section
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Order Number & Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Iconsax.receipt_2,
                                    color: statusColor,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Order #${order.orderNumber}',
                                  style: const TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 30),
                              child: Text(
                                timeAgo,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      _buildStatusBadge(statusColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Items Preview
                  if (order.items.isNotEmpty) ...[
                    SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          // Item thumbnails
                          ...order.items
                              .take(3)
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildItemThumbnail(item.imageUrl),
                                ),
                              ),
                          if (order.items.length > 3)
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '+${order.items.length - 3}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          const Spacer(),
                          // Total Price
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Bottom Actions
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.withOpacity(0.08)),
                ),
              ),
              child: Row(
                children: [
                  // Track Button
                  if (order.trackingNumber != null &&
                      order.status != OrderHistoryStatus.delivered &&
                      order.status != OrderHistoryStatus.cancelled)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onTrackPressed();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey.withOpacity(0.08),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Iconsax.location,
                                size: 16,
                                color: Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Track Order',
                                style: TextStyle(
                                  color: const Color(0xFF3B82F6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Details Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onDetailsPressed();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.document_text,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Proper image loading with error handling
  Widget _buildItemThumbnail(String imageUrl) {
    // ✅ Validate URL - skip if empty or invalid
    if (imageUrl.isEmpty || !_isValidImageUrl(imageUrl)) {
      return _buildPlaceholderThumbnail();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          // ✅ Error handling
          errorWidget: (context, url, error) => _buildPlaceholderThumbnail(),
          // ✅ Loading placeholder
          placeholder: (context, url) => Container(
            color: Colors.grey[100],
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ED573)),
                ),
              ),
            ),
          ),
          // ✅ Cache configuration
          cacheManager: _getCacheManager(),
          // ✅ MemCache configuration
          memCacheWidth: 100,
          memCacheHeight: 100,
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Center(
        child: Icon(Iconsax.box, color: Colors.grey[400], size: 20),
      ),
    );
  }

  // ✅ Validate image URL
  bool _isValidImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  // ✅ Custom cache manager with proper configuration
  CacheManager _getCacheManager() {
    return CacheManager(
      Config(
        'order_images_cache',
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 200,
      ),
    );
  }

  Widget _buildStatusBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            order.status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}
