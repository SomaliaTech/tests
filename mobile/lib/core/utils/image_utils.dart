// lib/core/utils/image_utils.dart
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageUtils {
  /// Validates if a URL points to a valid image
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);

      // Must have scheme and authority
      if (!uri.hasScheme || !uri.hasAuthority) {
        debugPrint('❌ ImageUtils: Invalid URL format - $url');
        return false;
      }

      // Check for common issues with Supabase URLs
      if (url.contains('supabase.co')) {
        // Supabase storage URLs should have proper path structure
        if (!url.contains('/storage/v1/object/public/')) {
          debugPrint('⚠️ ImageUtils: Suspicious Supabase URL - $url');
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ ImageUtils: Error parsing URL - $e');
      return false;
    }
  }

  /// Returns a fallback avatar widget if image is invalid
  static Widget buildSafeAvatar({
    required String? imageUrl,
    required String name,
    required double radius,
  }) {
    // Try to fix common Supabase URL issues
    final fixedUrl = _fixSupabaseUrl(imageUrl);

    if (fixedUrl == null) {
      return _buildFallbackAvatar(name, radius);
    }

    return _buildNetworkAvatar(fixedUrl, name, radius);
  }

  static String? _fixSupabaseUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // Fix double slashes (except after protocol)
    String fixed = url.replaceAll(RegExp(r'(?<!:)/{2,}'), '/');

    // Ensure proper Supabase storage path
    if (fixed.contains('supabase.co') &&
        !fixed.contains('/storage/v1/object/public/')) {
      debugPrint('⚠️ ImageUtils: Attempting to fix Supabase URL: $url');
      // This is a simplified fix - you may need to adjust based on your actual URL structure
    }

    return fixed;
  }

  static Widget _buildNetworkAvatar(String url, String name, double radius) {
    // Implementation using CachedNetworkImage
    // ... (similar to ChatAvatar widget)
    return CircleAvatar(
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
  }

  static Widget _buildFallbackAvatar(String name, double radius) {
    return CircleAvatar(
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
  }
}
