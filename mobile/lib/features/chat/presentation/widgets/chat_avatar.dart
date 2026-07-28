// lib/features/chat/presentation/widgets/chat_avatar.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final VoidCallback? onTap;
  final String? heroTag; // If null, no Hero wrapper

  const ChatAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 20,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade100,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: const Color(0xFF2ED573),
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty || !_isValidUrl(imageUrl!)) {
      return _buildAvatar(fallback);
    }

    return _buildAvatar(
      CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade100,
          child: SizedBox(
            width: radius,
            height: radius,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF2ED573).withOpacity(0.5),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint('❌ Avatar load failed for $url: $error');
          return fallback;
        },
        memCacheWidth: (radius * 4).toInt(),
        memCacheHeight: (radius * 4).toInt(),
        maxWidthDiskCache: (radius * 4).toInt(),
        maxHeightDiskCache: (radius * 4).toInt(),
      ),
    );
  }

  // ✅ Only wrap in Hero if heroTag is provided
  Widget _buildAvatar(Widget child) {
    Widget avatar = child;

    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: child);
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
}
