// lib/features/admin/presentation/widgets/banner_form/banner_image_upload.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/core/theme/theme.dart';

class BannerImageUpload extends StatelessWidget {
  final File? selectedImage;
  final bool isUploading;
  final String? uploadedImageUrl;
  final Function(File) onImageSelected;
  final VoidCallback onImageRemoved;
  final Function(String) onImageUploaded;
  final VoidCallback onUploadStarted;

  const BannerImageUpload({
    super.key,
    this.selectedImage,
    required this.isUploading,
    this.uploadedImageUrl,
    required this.onImageSelected,
    required this.onImageRemoved,
    required this.onImageUploaded,
    required this.onUploadStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Banner Image *',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isUploading ? null : () => _showImageSourceDialog(context),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedImage != null
                    ? AppTheme.primaryColor
                    : const Color(0xFFE5E7EB),
                width: 2,
              ),
            ),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (isUploading) return _buildUploadingState();
    if (selectedImage != null) return _buildImagePreview();
    return _buildEmptyState();
  }

  Widget _buildUploadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryColor,
            strokeWidth: 2.5,
          ),
          SizedBox(height: 12),
          Text(
            'Uploading...',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            selectedImage!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onImageRemoved,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.close_circle,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        if (uploadedImageUrl != null)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.tick_circle, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Uploaded',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.gallery_add, size: 48, color: Colors.grey),
        SizedBox(height: 12),
        Text(
          'Tap to upload image',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Recommended: 1920x1080',
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Select Image Source',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSourceOption(
              icon: Iconsax.gallery,
              label: 'Gallery',
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
            _buildSourceOption(
              icon: Iconsax.camera,
              label: 'Camera',
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            const Icon(Iconsax.arrow_right_3, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        onImageSelected(File(image.path));
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      debugPrint('Failed to pick image: $e');
    }
  }

  Future<void> _uploadImage(File image) async {
    onUploadStarted();

    try {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      final base64Image = 'data:image/jpeg;base64,$base64String';

      final storageService = sl<StorageService>();
      final token = await storageService.getAuthToken();

      if (token == null) throw Exception('Authentication required');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/banners/upload-image'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'image': base64Image,
          'fileName': 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        onImageUploaded(data['imageUrl']);
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    }
  }
}
