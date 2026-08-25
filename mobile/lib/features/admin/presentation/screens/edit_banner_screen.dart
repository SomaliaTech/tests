import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/services/injection_container.dart';

import 'package:mobile/features/product/domain/entities/banner.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_event.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_state.dart';

// ✅ Required imports for product picker
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_state.dart';

class EditBannerScreen extends StatefulWidget {
  final AppBanner banner;

  const EditBannerScreen({super.key, required this.banner});

  @override
  State<EditBannerScreen> createState() => _EditBannerScreenState();
}

class _EditBannerScreenState extends State<EditBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _imageUrlController;
  late TextEditingController _buttonTextController;
  late TextEditingController _actionLinkController;
  late TextEditingController _gradientStartController;
  late TextEditingController _gradientEndController;
  late TextEditingController _orderController;

  late bool _isActive;
  late bool _useGradient;
  bool _isLoading = false;
  bool _isUploading = false;

  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _useImageUpload = false;
  String? _originalImageUrl;

  final ImagePicker _imagePicker = ImagePicker();

  // ✅ Selected product info (like broadcast screen)
  String? _selectedProductId;
  String? _selectedProductName;
  String? _selectedProductSlug;

  // ==========================================
  // 🛡️ SAFE PROPERTY EXTRACTORS
  // ==========================================

  String? _extractImageUrl(dynamic product) {
    try {
      if (product.images != null && product.images.isNotEmpty) {
        final firstImage = product.images.first;
        if (firstImage.url != null) return firstImage.url.toString();
        if (firstImage.imageUrl != null) return firstImage.imageUrl.toString();
        if (firstImage.path != null) return firstImage.path.toString();
      }
    } catch (_) {}
    try {
      if (product.imageUrl != null) return product.imageUrl.toString();
    } catch (_) {}
    try {
      if (product.mainImage != null) return product.mainImage.toString();
    } catch (_) {}
    try {
      if (product.image != null) return product.image.toString();
    } catch (_) {}
    try {
      if (product.imageUrls != null && product.imageUrls.isNotEmpty) {
        return product.imageUrls.first.toString();
      }
    } catch (_) {}
    return null;
  }

  String _extractName(dynamic product) {
    try {
      return product.name?.toString() ?? 'Unknown Product';
    } catch (_) {
      return 'Unknown Product';
    }
  }

  String _extractPrice(dynamic product) {
    try {
      double priceValue = 0;
      if (product.finalPrice != null) {
        priceValue = (product.finalPrice as num).toDouble();
      } else if (product.price != null) {
        priceValue = (product.price as num).toDouble();
      }
      return '\$${priceValue.toStringAsFixed(2)}';
    } catch (_) {
      return '\$0.00';
    }
  }

  String _extractStock(dynamic product) {
    try {
      return product.stock?.toString() ?? '0';
    } catch (_) {
      return '0';
    }
  }

  String _extractSlugOrId(dynamic product) {
    try {
      if (product.slug != null && product.slug.toString().isNotEmpty) {
        return product.slug.toString();
      }
    } catch (_) {}
    try {
      return product.id?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.banner.title);
    _subtitleController = TextEditingController(
      text: widget.banner.subtitle ?? '',
    );
    _imageUrlController = TextEditingController(text: widget.banner.imageUrl);
    _buttonTextController = TextEditingController(
      text: widget.banner.buttonText ?? '',
    );
    _actionLinkController = TextEditingController(
      text: widget.banner.actionLink ?? '',
    );
    _gradientStartController = TextEditingController(
      text:
          widget.banner.gradientStart ??
          widget.banner.backgroundColor ??
          '#2ED573',
    );
    _gradientEndController = TextEditingController(
      text: widget.banner.gradientEnd ?? '#1ABC9C',
    );
    _orderController = TextEditingController(
      text: widget.banner.order.toString(),
    );
    _isActive = widget.banner.isActive;
    _useGradient = widget.banner.gradientStart != null;
    _originalImageUrl = widget.banner.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _imageUrlController.dispose();
    _buttonTextController.dispose();
    _actionLinkController.dispose();
    _gradientStartController.dispose();
    _gradientEndController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  // ==========================================
  // IMAGE HANDLING
  // ==========================================

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
        await _uploadImage();
      }
    } catch (e) {
      _showErrorToast('Failed to pick image: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
        await _uploadImage();
      }
    } catch (e) {
      _showErrorToast('Failed to capture image: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    setState(() => _isUploading = true);

    try {
      final bytes = await _selectedImage!.readAsBytes();
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
        setState(() {
          _uploadedImageUrl = data['imageUrl'];
          _isUploading = false;
        });
        _showSuccessToast('Image uploaded successfully');
      } else {
        String errorMessage = 'Upload failed: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) errorMessage = errorData['message'];
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showErrorToast('Failed to upload image: $e');
      debugPrint('❌ Upload error: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
      _useImageUpload = false;
    });
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Select Image Source',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImageSourceOption(
              icon: Iconsax.gallery,
              label: 'Gallery',
              onTap: () {
                Navigator.pop(dialogContext);
                _pickImageFromGallery();
              },
            ),
            const SizedBox(height: 12),
            _buildImageSourceOption(
              icon: Iconsax.camera,
              label: 'Camera',
              onTap: () {
                Navigator.pop(dialogContext);
                _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
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
                color: AppTheme.primaryColor.withOpacity(0.1),
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

  // ==========================================
  // TOASTS & FORM SUBMISSION
  // ==========================================

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

  void _updateBanner() {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    final imageUrl = _useImageUpload
        ? (_uploadedImageUrl ?? _originalImageUrl)
        : _imageUrlController.text.trim();

    if (imageUrl == null || imageUrl.isEmpty) {
      _showErrorToast('Please upload an image or provide an image URL');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final bannerData = {
      'title': _titleController.text.trim(),
      'subtitle': _subtitleController.text.trim().isNotEmpty
          ? _subtitleController.text.trim()
          : null,
      'imageUrl': imageUrl,
      'buttonText': _buttonTextController.text.trim().isNotEmpty
          ? _buttonTextController.text.trim()
          : null,
      'actionLink': _actionLinkController.text.trim().isNotEmpty
          ? _actionLinkController.text.trim()
          : null,
      'backgroundColor': _useGradient
          ? null
          : _gradientStartController.text.trim(),
      'gradientStart': _useGradient
          ? _gradientStartController.text.trim()
          : null,
      'gradientEnd': _useGradient ? _gradientEndController.text.trim() : null,
      'isActive': _isActive,
      'order': int.tryParse(_orderController.text) ?? 0,
    };

    context.read<AdminBannerBloc>().add(
      UpdateBannerEvent(id: widget.banner.id, bannerData: bannerData),
    );
  }

  // ==========================================
  // PRODUCT PICKER - ONLY PRODUCT SELECTION (like broadcast)
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
          _actionLinkController.text = '/products/$linkTarget';
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

  // ==========================================
  // PRODUCT SELECTOR WIDGET (like broadcast)
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
                        _actionLinkController.clear();
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
  // BUILD METHOD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Banner',
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
                  _buildPreviewCard(),
                  const SizedBox(height: 20),

                  // Basic Information
                  _buildSectionCard(
                    title: 'Basic Information',
                    icon: Iconsax.info_circle,
                    children: [
                      _buildTextField(
                        controller: _titleController,
                        label: 'Title *',
                        hint: 'Summer Sale 50% Off',
                        icon: Iconsax.text,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Title is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _subtitleController,
                        label: 'Subtitle',
                        hint: 'Grab the best deals',
                        icon: Iconsax.copy,
                        maxLines: 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Image Upload Section
                  _buildSectionCard(
                    title: 'Banner Image',
                    icon: Iconsax.image,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _useImageUpload = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _useImageUpload
                                        ? AppTheme.primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Iconsax.image,
                                        color: _useImageUpload
                                            ? Colors.white
                                            : Colors.grey,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Upload',
                                        style: TextStyle(
                                          color: _useImageUpload
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
                                onTap: () =>
                                    setState(() => _useImageUpload = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_useImageUpload
                                        ? AppTheme.primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Iconsax.link,
                                        color: !_useImageUpload
                                            ? Colors.white
                                            : Colors.grey,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'URL',
                                        style: TextStyle(
                                          color: !_useImageUpload
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
                      ),
                      const SizedBox(height: 16),
                      if (_useImageUpload)
                        _buildImageUploadSection()
                      else
                        _buildTextField(
                          controller: _imageUrlController,
                          label: 'Image URL *',
                          hint: 'https://example.com/banner.jpg',
                          icon: Iconsax.link,
                          validator: (value) {
                            if (_useImageUpload) return null;
                            if (value == null || value.trim().isEmpty)
                              return 'Image URL is required';
                            return null;
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Button & Action
                  _buildSectionCard(
                    title: 'Button & Action',
                    icon: Iconsax.mouse,
                    children: [
                      _buildTextField(
                        controller: _buttonTextController,
                        label: 'Button Text',
                        hint: 'Shop Now',
                        icon: Iconsax.text,
                      ),
                      const SizedBox(height: 16),
                      // ✅ Product selector instead of action link selector
                      _buildProductSelector(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Colors
                  _buildSectionCard(
                    title: 'Background Colors',
                    icon: Iconsax.colorfilter,
                    children: [
                      _buildSwitch(
                        label: 'Use Gradient',
                        value: _useGradient,
                        onChanged: (value) =>
                            setState(() => _useGradient = value),
                      ),
                      const SizedBox(height: 16),
                      if (_useGradient) ...[
                        _buildTextField(
                          controller: _gradientStartController,
                          label: 'Gradient Start Color',
                          hint: '#2ED573',
                          icon: Iconsax.color_swatch,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _gradientEndController,
                          label: 'Gradient End Color',
                          hint: '#1ABC9C',
                          icon: Iconsax.color_swatch,
                        ),
                      ] else ...[
                        _buildTextField(
                          controller: _gradientStartController,
                          label: 'Background Color',
                          hint: '#2ED573',
                          icon: Iconsax.color_swatch,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Settings
                  _buildSectionCard(
                    title: 'Settings',
                    icon: Iconsax.setting_2,
                    children: [
                      const SizedBox(height: 16),
                      _buildSwitch(
                        label: 'Active',
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isUploading
                          ? null
                          : _updateBanner,
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
                                Icon(Iconsax.edit_2, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Update Banner',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // REUSABLE WIDGET HELPERS
  // ==========================================

  Widget _buildImageUploadSection() {
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
          onTap: _isUploading ? null : _showImageSourceDialog,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedImage != null
                    ? AppTheme.primaryColor
                    : const Color(0xFFE5E7EB),
                width: 2,
              ),
            ),
            child: _isUploading
                ? const Center(
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
                  )
                : _selectedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _removeImage,
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
                      if (_uploadedImageUrl != null)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.tick_circle,
                                  color: Colors.white,
                                  size: 12,
                                ),
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
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.gallery_add, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Tap to upload new image',
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
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    final previewImageUrl = _useImageUpload
        ? (_uploadedImageUrl ??
              (_selectedImage != null
                  ? 'file://${_selectedImage!.path}'
                  : _originalImageUrl))
        : (_imageUrlController.text.isNotEmpty
              ? _imageUrlController.text
              : _originalImageUrl);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: _useGradient
                    ? LinearGradient(
                        colors: [
                          _hexToColor(_gradientStartController.text),
                          _hexToColor(_gradientEndController.text),
                        ],
                      )
                    : null,
                color: _useGradient
                    ? null
                    : _hexToColor(_gradientStartController.text),
              ),
              child: previewImageUrl != null
                  ? previewImageUrl.startsWith('file://')
                        ? Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Iconsax.image,
                                size: 48,
                                color: Colors.white54,
                              ),
                            ),
                          )
                        : Image.network(
                            previewImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Iconsax.image,
                                size: 48,
                                color: Colors.white54,
                              ),
                            ),
                          )
                  : const Center(
                      child: Icon(
                        Iconsax.image,
                        size: 48,
                        color: Colors.white54,
                      ),
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleController.text.isEmpty
                        ? 'Banner Title'
                        : _titleController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_subtitleController.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _subtitleController.text,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (_selectedProductName != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.box_1,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedProductName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_buttonTextController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _buttonTextController.text,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: Color(0xFF1F2937)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF2ED573),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
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
