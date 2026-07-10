import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ==========================================
  // Splash Screen Colors - Red Floral Theme
  // ==========================================

  // Gradient Background Colors
  static const Color splashBgWhite = Color(0xFFFFFFFF);
  static const Color splashBgOffWhite = Color(0xFFFEFEFE);
  static const Color splashBgLightPink = Color(0xFFFDF2F2);
  static const Color splashBgRoseWhite = Color(0xFFFCE4E4);

  // Red/Pink Brand Colors
  static const Color primaryRed = Color(0xFFFF1744);
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color deepRose = Color(0xFFC2185B);
  static const Color darkMagenta = Color(0xFF880E4F);

  // Decorative Circle Colors with Opacity
  static Color decorativeCircleLarge = const Color(
    0xFFE91E63,
  ).withValues(alpha: 0.08);
  static Color decorativeCircleMedium = const Color(
    0xFFFF1744,
  ).withValues(alpha: 0.06);
  static Color decorativeCircleSmall = const Color(
    0xFFC2185B,
  ).withValues(alpha: 0.05);

  // Petal/Dot Colors
  static Color petalDotPrimary = const Color(0xFFE91E63).withValues(alpha: 0.3);
  static Color petalDotSecondary = const Color(
    0xFFFF1744,
  ).withValues(alpha: 0.25);
  static Color petalDotTertiary = const Color(
    0xFFC2185B,
  ).withValues(alpha: 0.2);

  // Logo Container Colors
  static const Color logoBackground = Colors.white;
  static Color logoShadowPrimary = const Color(
    0xFFE91E63,
  ).withValues(alpha: 0.15);
  static Color logoShadowSecondary = const Color(
    0xFFFF1744,
  ).withValues(alpha: 0.08);
  static Color logoInnerRing = const Color(0xFFE91E63).withValues(alpha: 0.15);
  static Color logoSecondRing = const Color(0xFFFF1744).withValues(alpha: 0.08);
  static const Color logoIcon = Color(0xFFE91E63);

  // Text Colors
  static const Color textAppName = Color(0xFFC2185B);
  static Color textAppNameShadow = const Color(0x20E91E63);
  static const Color textTagline = Color(0xFFC2185B);

  // Tagline Container Colors
  static Color taglineBgGradient1 = const Color(
    0xFFE91E63,
  ).withValues(alpha: 0.08);
  static Color taglineBgGradient2 = const Color(
    0xFFFF1744,
  ).withValues(alpha: 0.05);
  static Color taglineBorder = const Color(0xFFE91E63).withValues(alpha: 0.2);

  // Loading Indicator Colors
  static Color loadingIndicator = const Color(
    0xFFE91E63,
  ).withValues(alpha: 0.8);
  static Color loadingIndicatorBg = const Color(
    0xFFE91E63,
  ).withValues(alpha: 0.1);
  static const Color loadingDotGradient1 = Color(0xFFE91E63);
  static const Color loadingDotGradient2 = Color(0xFFFF1744);
  static Color loadingDotShadow = const Color(
    0xFFE91E63,
  ).withValues(alpha: 0.3);

  // Version Container Colors
  static Color versionContainerBg = const Color(
    0xFFE91E63,
  ).withValues(alpha: 0.06);
  static Color versionContainerBorder = const Color(
    0xFFE91E63,
  ).withValues(alpha: 0.1);
  static const Color versionText = Color(0xFFC2185B);
}
