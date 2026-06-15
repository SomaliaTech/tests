import 'dart:convert'; // CRITICAL: Gives access to native base64.encode
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';

class ProfileImagePicker extends StatelessWidget {
  final String? imageUrl;
  final Function(String) onImagePicked;

  const ProfileImagePicker({
    super.key,
    required this.imageUrl,
    required this.onImagePicked,
  });

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    // imageQuality: 70 compresses the image slightly to save bandwidth
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();

      // FIX: Use the native base64 utilities instead of custom loop string conversions
      final base64String = base64.encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64String';

      onImagePicked(dataUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        child: Column(
          children: [
            Stack(
              children: [
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  ClipOval(
                    child: Image.network(
                      imageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    ),
                  )
                else
                  _buildPlaceholder(),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2ED573),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.camera,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Change Photo',
              style: TextStyle(
                color: Color(0xFF2ED573),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        shape: BoxShape.circle,
      ),
      child: const Icon(Iconsax.user, size: 40, color: Color(0xFF999999)),
    );
  }
}
