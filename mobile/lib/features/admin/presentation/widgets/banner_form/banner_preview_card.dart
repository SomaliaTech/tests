// lib/features/admin/presentation/widgets/banner_form/banner_preview_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile/features/product/data/models/banner_form_data.dart';

class BannerPreviewCard extends StatelessWidget {
  final BannerFormData formData;
  final File? selectedImage;

  const BannerPreviewCard({
    super.key,
    required this.formData,
    this.selectedImage,
  });

  @override
  Widget build(BuildContext context) {
    final previewImageUrl = _getPreviewImageUrl();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background
            _buildBackground(previewImageUrl),

            // Gradient Overlay
            _buildOverlay(),

            // Content
            _buildContent(),

            // Discount Badge
            if (formData.hasDiscount) _buildDiscountBadge(),

            // Flash Sale Timer
            if (formData.isFlashSale) _buildFlashSaleTimer(),
          ],
        ),
      ),
    );
  }

  String? _getPreviewImageUrl() {
    if (formData.useImageUpload) {
      if (formData.uploadedImageUrl != null) return formData.uploadedImageUrl;
      if (selectedImage != null) return 'file://${selectedImage!.path}';
      return null;
    }
    return formData.imageUrl?.isNotEmpty == true ? formData.imageUrl : null;
  }

  Widget _buildBackground(String? imageUrl) {
    return Container(
      decoration: BoxDecoration(
        gradient: formData.useGradient
            ? LinearGradient(
                colors: [
                  _hexToColor(formData.gradientStart ?? '#2ED573'),
                  _hexToColor(formData.gradientEnd ?? '#1ABC9C'),
                ],
              )
            : null,
        color: formData.useGradient
            ? null
            : _hexToColor(formData.gradientStart ?? '#2ED573'),
      ),
      child: imageUrl != null
          ? imageUrl.startsWith('file://')
                ? Image.file(
                    selectedImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.white54),
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.white54),
                    ),
                  )
          : const Center(
              child: Icon(Icons.image, size: 48, color: Colors.white54),
            ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
          stops: const [0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formData.title.isEmpty ? 'Banner Title' : formData.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (formData.subtitle?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              formData.subtitle!,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          if (formData.buttonText?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                formData.buttonText!,
                style: const TextStyle(
                  color: Color(0xFF2ED573),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscountBadge() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4757), Color(0xFFFF6B81)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.discount, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              formData.discountPercentage != null
                  ? '${formData.discountPercentage!.toInt()}% OFF'
                  : 'SALE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashSaleTimer() {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flash_on, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'FLASH SALE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF2ED573);
    }
  }
}
