import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SafeNetworkImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.radius = 0,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Check if URL is valid
    if (imageUrl == null || imageUrl!.isEmpty || !_isValidUrl(imageUrl!)) {
      return _buildFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ??
            Container(
              color: Colors.grey[100],
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        errorWidget: (context, url, error) {
          // ✅ Log the error silently
          debugPrint('⚠️ Image load failed: $url - $error');
          return errorWidget ?? _buildFallback();
        },
        // ✅ Add cache configuration
        cacheManager: null, // Use default cache
        maxWidthDiskCache: 200,
        maxHeightDiskCache: 200,
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(Iconsax.gallery, size: 24, color: Colors.grey[400]),
    );
  }

  bool _isValidUrl(String url) {
    // ✅ Check for common invalid patterns
    if (url.contains('placeholder') ||
        url.contains('undefined') ||
        url.contains('null') ||
        url == '') {
      return false;
    }

    // ✅ Basic URL validation
    try {
      final uri = Uri.tryParse(url);
      return uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
