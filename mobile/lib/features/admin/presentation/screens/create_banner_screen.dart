// lib/features/admin/presentation/screens/create_banner_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_event.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_state.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_discount_section.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_flash_sale_section.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_form_fields.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_preview_card.dart';

import 'package:mobile/features/product/data/models/banner_form_data.dart';
import 'package:toastification/toastification.dart';

// ✅ Required imports for product picker
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_state.dart';
import 'package:iconsax/iconsax.dart';

class CreateBannerScreen extends StatefulWidget {
  const CreateBannerScreen({super.key});

  @override
  State<CreateBannerScreen> createState() => _CreateBannerScreenState();
}

class _CreateBannerScreenState extends State<CreateBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formData = BannerFormData.create();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;

  // ✅ Selected product info
  String? _selectedProductId;
  String? _selectedProductName;
  String? _selectedProductSlug;

  // ✅ Helper method to trigger rebuild
  void _onFormChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Banner',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AdminBannerBloc, AdminBannerState>(
        listener: (context, state) {
          if (state is AdminBannerOperationSuccess) {
            setState(() => _isLoading = false);
            _showSuccessToast(state.message);
            Navigator.pop(context);
          } else if (state is AdminBannerError) {
            setState(() => _isLoading = false);
            _showErrorToast(state.message);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview Card
                  BannerPreviewCard(
                    formData: _formData,
                    selectedImage: _selectedImage,
                    selectedProductName: _selectedProductName,
                  ),
                  const SizedBox(height: 20),

                  // Form Fields
                  BannerFormFields(
                    formData: _formData,
                    selectedImage: _selectedImage,
                    isUploading: _isUploading,
                    onImageSelected: (file) =>
                        setState(() => _selectedImage = file),
                    onImageRemoved: () => setState(() {
                      _selectedImage = null;
                      _formData.uploadedImageUrl = null;
                    }),
                    onImageUploaded: (url) {
                      setState(() {
                        _formData.uploadedImageUrl = url;
                        _isUploading = false;
                      });
                    },
                    onUploadStarted: () => setState(() => _isUploading = true),
                    onFormChanged: _onFormChanged,
                  ),
                  const SizedBox(height: 16),

                  // ✅ PRODUCT SELECTOR
                  _buildProductSelector(),
                  const SizedBox(height: 16),

                  // ✅ Discount Section - FIXED: Added onChanged
                  BannerDiscountSection(
                    formData: _formData,
                    onChanged: _onFormChanged,
                  ),
                  const SizedBox(height: 16),

                  // ✅ Flash Sale Section - FIXED: Added onChanged
                  BannerFlashSaleSection(
                    formData: _formData,
                    onChanged: _onFormChanged,
                  ),
                  const SizedBox(height: 24),

                  // Create Button
                  _buildCreateButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // PRODUCT SELECTOR
  // ==========================================
  Widget _buildProductSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Product (Optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showProductPicker,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedProductId != null
                    ? const Color(0xFF2ED573)
                    : const Color(0xFFE5E7EB),
                width: _selectedProductId != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.box_1,
                    color: Color(0xFF2ED573),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedProductName ?? 'Tap to select a product',
                        style: TextStyle(
                          color: _selectedProductId != null
                              ? const Color(0xFF1F2937)
                              : const Color(0xFF9CA3AF),
                          fontSize: 14,
                          fontWeight: _selectedProductId != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (_selectedProductId != null)
                        Text(
                          'Selected product will be linked',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_selectedProductId != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedProductId = null;
                        _selectedProductName = null;
                        _selectedProductSlug = null;
                        _formData.actionLink = null;
                      });
                    },
                    child: const Icon(
                      Iconsax.close_circle,
                      color: Colors.grey,
                      size: 20,
                    ),
                  )
                else
                  const Icon(
                    Iconsax.arrow_down_1,
                    color: Colors.grey,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // PRODUCT PICKER
  // ==========================================
  void _showProductPicker() {
    final currentState = context.read<AdminProductBloc>().state;

    if (currentState is AdminProductsLoaded &&
        currentState.products.isNotEmpty) {
      _showProductPickerSheet();
      return;
    }

    context.read<AdminProductBloc>().add(FetchAllAdminProductsEvent());
    _showProductPickerSheet();
  }

  void _showProductPickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select a Product',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BlocBuilder<AdminProductBloc, AdminProductState>(
                    builder: (context, state) {
                      if (state is AdminProductsLoading) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF2ED573),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading products...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                      if (state is AdminProductsLoaded) {
                        if (state.products.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.box, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  'No products found.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: state.products.length,
                          itemBuilder: (context, index) {
                            final product = state.products[index];
                            return _buildProductListItem(product);
                          },
                        );
                      }
                      if (state is AdminProductsError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Iconsax.warning_2,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Error: ${state.message}',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<AdminProductBloc>().add(
                                    FetchAllAdminProductsEvent(),
                                  );
                                },
                                icon: const Icon(Iconsax.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2ED573),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2ED573),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductListItem(dynamic product) {
    String? imageUrl;

    // ✅ Extract image from AdminProductModel
    try {
      if (product.images != null && product.images.isNotEmpty) {
        final firstImage = product.images.first;
        try {
          if (firstImage.url != null && firstImage.url.toString().isNotEmpty) {
            imageUrl = firstImage.url.toString();
          }
        } catch (_) {}
        if (imageUrl == null) {
          try {
            if (firstImage is Map) {
              if (firstImage['url'] != null &&
                  firstImage['url'].toString().isNotEmpty) {
                imageUrl = firstImage['url'].toString();
              }
            }
          } catch (_) {}
        }
        if (imageUrl == null) {
          try {
            if (firstImage is String && firstImage.isNotEmpty) {
              imageUrl = firstImage;
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    if (imageUrl == null) {
      try {
        if (product.imageUrl != null &&
            product.imageUrl.toString().isNotEmpty) {
          imageUrl = product.imageUrl.toString();
        }
      } catch (_) {}
    }
    if (imageUrl == null) {
      try {
        if (product.mainImage != null &&
            product.mainImage.toString().isNotEmpty) {
          imageUrl = product.mainImage.toString();
        }
      } catch (_) {}
    }
    if (imageUrl == null) {
      try {
        if (product.image != null && product.image.toString().isNotEmpty) {
          imageUrl = product.image.toString();
        }
      } catch (_) {}
    }
    if (imageUrl == null) {
      try {
        if (product.imageUrls != null && product.imageUrls.isNotEmpty) {
          imageUrl = product.imageUrls.first.toString();
        }
      } catch (_) {}
    }

    // Extract name
    String name = 'Unknown Product';
    try {
      if (product.name != null) {
        name = product.name.toString();
      }
    } catch (_) {}

    // Extract price
    String price = '\$0.00';
    try {
      double priceValue = 0;
      if (product.finalPrice != null) {
        priceValue = (product.finalPrice as num).toDouble();
      } else if (product.price != null) {
        priceValue = (product.price as num).toDouble();
      }
      price = '\$${priceValue.toStringAsFixed(2)}';
    } catch (_) {}

    // Extract slug or id for link
    String linkTarget = '';
    try {
      if (product.slug != null && product.slug.toString().isNotEmpty) {
        linkTarget = product.slug.toString();
      } else if (product.id != null) {
        linkTarget = product.id.toString();
      }
    } catch (_) {}

    if (linkTarget.isEmpty) {
      linkTarget = 'product_${DateTime.now().millisecondsSinceEpoch}';
    }

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _selectedProductId = linkTarget;
          _selectedProductName = name;
          _selectedProductSlug = linkTarget;
          _formData.actionLink = '/products/$linkTarget';
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _selectedProductId == linkTarget
              ? const Color(0xFF2ED573).withOpacity(0.1)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedProductId == linkTarget
                ? const Color(0xFF2ED573)
                : const Color(0xFFE5E7EB),
            width: _selectedProductId == linkTarget ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          debugPrint('❌ Failed to load image: $imageUrl');
                        },
                      )
                    : null,
              ),
              child: imageUrl == null || imageUrl.isEmpty
                  ? const Icon(Iconsax.image, color: Colors.grey, size: 24)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (_selectedProductId == linkTarget)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF2ED573),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.tick_circle,
                  color: Colors.white,
                  size: 18,
                ),
              )
            else
              const Icon(Iconsax.arrow_right_3, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading || _isUploading ? null : _createBanner,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2ED573),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading || _isUploading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Create Banner',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  void _createBanner() {
    // ✅ Use built-in validation
    final error = _formData.validate();
    if (error != null) {
      _showErrorToast(error);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    context.read<AdminBannerBloc>().add(
      CreateBannerEvent(bannerData: _formData.toJson()),
    );
  }

  void _showSuccessToast(String message) {
    toastification.show(
      context: context,
      title: Text(message),
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _showErrorToast(String message) {
    toastification.show(
      context: context,
      title: Text(message),
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}
