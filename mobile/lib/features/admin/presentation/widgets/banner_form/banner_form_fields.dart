// lib/features/admin/presentation/widgets/banner_form/banner_form_fields.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_action_link_selector.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_image_upload.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_section_card.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_text_field.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_switch.dart';
import 'package:mobile/features/product/data/models/banner_form_data.dart';

class BannerFormFields extends StatelessWidget {
  final BannerFormData formData;
  final File? selectedImage;
  final bool isUploading;
  final Function(File) onImageSelected;
  final VoidCallback onImageRemoved;
  final Function(String) onImageUploaded;
  final VoidCallback onUploadStarted;
  final VoidCallback onFormChanged;

  const BannerFormFields({
    super.key,
    required this.formData,
    this.selectedImage,
    required this.isUploading,
    required this.onImageSelected,
    required this.onImageRemoved,
    required this.onImageUploaded,
    required this.onUploadStarted,
    required this.onFormChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Basic Information
        BannerSectionCard(
          title: 'Basic Information',
          icon: Iconsax.info_circle,
          children: [
            BannerTextField(
              label: 'Title *',
              hint: 'Summer Sale 50% Off',
              icon: Iconsax.text,
              initialValue: formData.title,
              onChanged: (value) {
                formData.title = value;
                onFormChanged();
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            BannerTextField(
              label: 'Subtitle',
              hint: 'Grab the best deals',
              icon: Iconsax.copy,
              initialValue: formData.subtitle,
              maxLines: 2,
              onChanged: (value) {
                formData.subtitle = value;
                onFormChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Image Upload
        BannerSectionCard(
          title: 'Banner Image',
          icon: Iconsax.image,
          children: [
            // Toggle between Upload and URL
            _buildImageToggle(),
            const SizedBox(height: 16),

            if (formData.useImageUpload)
              BannerImageUpload(
                selectedImage: selectedImage,
                isUploading: isUploading,
                uploadedImageUrl: formData.uploadedImageUrl,
                onImageSelected: onImageSelected,
                onImageRemoved: onImageRemoved,
                onImageUploaded: onImageUploaded,
                onUploadStarted: onUploadStarted,
              )
            else
              BannerTextField(
                label: 'Image URL *',
                hint: 'https://example.com/banner.jpg',
                icon: Iconsax.link,
                initialValue: formData.imageUrl,
                onChanged: (value) {
                  formData.imageUrl = value;
                  onFormChanged();
                },
                validator: (value) {
                  if (formData.useImageUpload) return null;
                  if (value == null || value.trim().isEmpty) {
                    return 'Image URL is required';
                  }
                  return null;
                },
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Button & Action
        BannerSectionCard(
          title: 'Button & Action',
          icon: Iconsax.mouse,
          children: [
            BannerTextField(
              label: 'Button Text',
              hint: 'Shop Now',
              icon: Iconsax.text,
              initialValue: formData.buttonText,
              onChanged: (value) {
                formData.buttonText = value;
                onFormChanged();
              },
            ),
            const SizedBox(height: 16),
            BannerActionLinkSelector(
              formData: formData,
              onFormChanged: onFormChanged,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Colors
        BannerSectionCard(
          title: 'Background Colors',
          icon: Iconsax.colorfilter,
          children: [
            BannerSwitch(
              label: 'Use Gradient',
              value: formData.useGradient,
              onChanged: (value) {
                formData.useGradient = value;
                onFormChanged();
              },
            ),
            const SizedBox(height: 16),
            if (formData.useGradient) ...[
              BannerTextField(
                label: 'Gradient Start Color',
                hint: '#2ED573',
                icon: Iconsax.color_swatch,
                initialValue: formData.gradientStart,
                onChanged: (value) {
                  formData.gradientStart = value;
                  onFormChanged();
                },
              ),
              const SizedBox(height: 16),
              BannerTextField(
                label: 'Gradient End Color',
                hint: '#1ABC9C',
                icon: Iconsax.color_swatch,
                initialValue: formData.gradientEnd,
                onChanged: (value) {
                  formData.gradientEnd = value;
                  onFormChanged();
                },
              ),
            ] else ...[
              BannerTextField(
                label: 'Background Color',
                hint: '#2ED573',
                icon: Iconsax.color_swatch,
                initialValue: formData.gradientStart,
                onChanged: (value) {
                  formData.gradientStart = value;
                  onFormChanged();
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Settings
        BannerSectionCard(
          title: 'Settings',
          icon: Iconsax.setting_2,
          children: [
            BannerSwitch(
              label: 'Active',
              value: formData.isActive,
              onChanged: (value) {
                formData.isActive = value;
                onFormChanged();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                formData.useImageUpload = true;
                onFormChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: formData.useImageUpload
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.image,
                      color: formData.useImageUpload
                          ? Colors.white
                          : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Upload',
                      style: TextStyle(
                        color: formData.useImageUpload
                            ? Colors.white
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                formData.useImageUpload = false;
                onFormChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !formData.useImageUpload
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.link,
                      color: !formData.useImageUpload
                          ? Colors.white
                          : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'URL',
                      style: TextStyle(
                        color: !formData.useImageUpload
                            ? Colors.white
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
