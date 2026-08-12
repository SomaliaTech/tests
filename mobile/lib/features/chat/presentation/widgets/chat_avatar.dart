import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name; // Made nullable to be safe
  final double radius;
  final VoidCallback? onTap;
  final String? heroTag;

  const ChatAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    // Generate initials and color for fallback
    final initials = _getInitials();
    final bgColor = _getAvatarColor();

    // This is the fallback widget shown while loading or on error
    final fallbackWidget = CircleAvatar(
      radius: radius,
      backgroundColor: bgColor.withOpacity(0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: bgColor,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.85,
        ),
      ),
    );

    // Check if we have a valid URL
    final hasValidImage =
        imageUrl != null && imageUrl!.isNotEmpty && _isValidUrl(imageUrl!);

    Widget avatarContent;

    if (!hasValidImage) {
      // No image provided, show initials immediately
      avatarContent = fallbackWidget;
    } else {
      // Load network image with cached_network_image
      avatarContent = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          // Show colored initials while downloading
          placeholder: (context, url) => fallbackWidget,
          // Show colored initials if image fails (corrupted cache, 404, etc.)
          errorWidget: (context, url, error) {
            debugPrint('❌ Avatar load failed for $url: $error');
            return fallbackWidget;
          },
          // Optimize cache size for avatars
          memCacheWidth: (radius * 4).toInt(),
          memCacheHeight: (radius * 4).toInt(),
          maxWidthDiskCache: (radius * 4).toInt(),
          maxHeightDiskCache: (radius * 4).toInt(),
        ),
      );
    }

    // Wrap in Hero if tag is provided (for smooth transitions to ChatRoom)
    Widget result = heroTag != null
        ? Hero(tag: heroTag!, child: avatarContent)
        : avatarContent;

    // Wrap in GestureDetector if onTap is provided
    if (onTap != null) {
      result = GestureDetector(onTap: onTap, child: result);
    }

    return result;
  }

  // Generate smart initials (First + Last initial)
  String _getInitials() {
    if (name == null || name!.trim().isEmpty) return '?';

    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // Generate a consistent color based on the user's name hash
  Color _getAvatarColor() {
    final colorIndex = (name?.hashCode ?? 0).abs() % 6;
    const colors = [
      Color(0xFF2ED573), // Green
      Color(0xFF3B82F6), // Blue
      Color(0xFFF59E0B), // Orange
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEF4444), // Red
      Color(0xFF06B6D4), // Cyan
    ];
    return colors[colorIndex];
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
