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

// ✅ Required imports for visual pickers
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
  // ==========================================
  // 🛡️ SAFE PROPERTY EXTRACTORS (Prevents NoSuchMethodError)
  // ==========================================

  String? _extractImageUrl(dynamic product) {
    try {
      if (product.imageUrl != null) return product.imageUrl.toString();
    } catch (_) {}
    try {
      if (product.mainImage != null) return product.mainImage.toString();
    } catch (_) {}
    try {
      if (product.images != null && product.images.isNotEmpty) {
        final firstImage = product.images.first;
        if (firstImage is String) return firstImage;
        if (firstImage.url != null) return firstImage.url.toString();
      }
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
      return product.name ?? 'Unknown Product';
    } catch (_) {
      return 'Unknown Product';
    }
  }

  String _extractPrice(dynamic product) {
    try {
      return '\$${(product.price as num).toStringAsFixed(2)}';
    } catch (_) {
      return '\$0.00';
    }
  }

  String _extractStock(dynamic product) {
    try {
      return '${product.stock}';
    } catch (_) {
      return '0';
    }
  }

  String _extractSlugOrId(dynamic product) {
    try {
      if (product.slug != null && product.slug.toString().isNotEmpty)
        return product.slug;
    } catch (_) {}
    try {
      return product.id;
    } catch (_) {
      return '';
    }
  }

  String _extractCategoryName(dynamic category) {
    try {
      return category.name ?? 'Unknown Category';
    } catch (_) {
      return 'Unknown Category';
    }
  }

  String _extractCategoryDescription(dynamic category) {
    try {
      return category.description ?? '';
    } catch (_) {
      return '';
    }
  }

  String _extractCategorySlugOrId(dynamic category) {
    try {
      if (category.slug != null && category.slug.toString().isNotEmpty)
        return category.slug;
    } catch (_) {}
    try {
      return category.id;
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
  // VISUAL ACTION LINK SELECTOR
  // ==========================================

  Widget _buildActionLinkSelector() {
    final link = _actionLinkController.text;

    String displayText = 'Select a destination...';
    IconData displayIcon = Iconsax.link_21;
    Color displayColor = Colors.grey;

    if (link.isNotEmpty) {
      if (link == '/home') {
        displayText = 'Home Page';
        displayIcon = Iconsax.home_2;
        displayColor = Colors.blue;
      } else if (link == '/categories') {
        displayText = 'All Categories';
        displayIcon = Iconsax.category;
        displayColor = Colors.purple;
      } else if (link == '/hot-deals') {
        displayText = 'Hot Deals Section';
        displayIcon = Iconsax.flash_1;
        displayColor = Colors.red;
      } else if (link == '/latest-products') {
        displayText = 'Latest Products';
        displayIcon = Iconsax.star;
        displayColor = Colors.green;
      } else if (link.startsWith('/products/category/')) {
        displayText = 'Category: ${link.split('/').last}';
        displayIcon = Iconsax.cake;
        displayColor = Colors.orange;
      } else if (link.startsWith('/products/')) {
        displayText = 'Product: ${link.split('/').last}';
        displayIcon = Iconsax.box_1;
        displayColor = Colors.teal;
      } else {
        displayText = 'Custom: $link';
        displayIcon = Iconsax.link;
        displayColor = Colors.indigo;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Button Destination (Where should it take the user?)',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showLinkSelectorSheet,
          child: Container(
            padding: const EdgeInsets.all(14),
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
                    color: displayColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(displayIcon, color: displayColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: link.isEmpty
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF1F2937),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (link.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _actionLinkController.clear()),
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

  void _showLinkSelectorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
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
                      'Choose Destination',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const Text(
                        'Specific Targets',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSheetOption(
                        Iconsax.cake,
                        'Select Category',
                        'Link to a specific category',
                        Colors.orange,
                        () {
                          Navigator.pop(ctx);
                          _showCategoryPicker();
                        },
                      ),
                      _buildSheetOption(
                        Iconsax.box_1,
                        'Select Product',
                        'Link to a specific product',
                        Colors.teal,
                        () {
                          Navigator.pop(ctx);
                          _showProductPicker();
                        },
                      ),
                      const Divider(height: 32),
                      _buildSheetOption(
                        Iconsax.link,
                        'Custom Link',
                        'Enter a custom path or URL',
                        Colors.grey,
                        () {
                          Navigator.pop(ctx);
                          _showCustomLinkDialog();
                        },
                      ),
                      const Divider(height: 32),
                      const SizedBox(height: 20),
                      _buildSheetOption(
                        Iconsax.home_2,
                        'Home Page',
                        'Main landing page',
                        Colors.blue,
                        () {
                          Navigator.pop(ctx);
                          _selectLink('/home');
                        },
                      ),
                      _buildSheetOption(
                        Iconsax.category,
                        'All Categories',
                        'Browse all categories',
                        Colors.purple,
                        () {
                          Navigator.pop(ctx);
                          _selectLink('/categories');
                        },
                      ),
                      _buildSheetOption(
                        Iconsax.flash_1,
                        'Hot Deals',
                        'Discounted items section',
                        Colors.red,
                        () {
                          Navigator.pop(ctx);
                          _selectLink('/hot-deals');
                        },
                      ),
                      _buildSheetOption(
                        Iconsax.star,
                        'Latest Products',
                        'New arrivals section',
                        Colors.green,
                        () {
                          Navigator.pop(ctx);
                          _selectLink('/latest-products');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetOption(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Iconsax.arrow_right_3, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _selectLink(String link) {
    setState(() => _actionLinkController.text = link);
  }

  // ==========================================
  // ✅ VISUAL PRODUCT PICKER (Reads from BLoC)
  // ==========================================
  void _showProductPicker() {
    context.read<AdminProductBloc>().add(FetchAllAdminProductsEvent());

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
                          child: CircularProgressIndicator(
                            color: Color(0xFF2ED573),
                          ),
                        );
                      }
                      if (state is AdminProductsLoaded) {
                        if (state.products.isEmpty) {
                          return const Center(
                            child: Text(
                              'No products found.',
                              style: TextStyle(color: Colors.grey),
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
                          child: Text(
                            'Error: ${state.message}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
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
    final imageUrl = _extractImageUrl(product);
    final name = _extractName(product);
    final price = _extractPrice(product);
    final stock = _extractStock(product);
    final linkTarget = _extractSlugOrId(product);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _selectLink('/products/$linkTarget');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
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
                    '$price • Stock: $stock',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Iconsax.arrow_right_3, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ✅ VISUAL CATEGORY PICKER (Reads from BLoC)
  // ==========================================
  void _showCategoryPicker() {
    context.read<AdminProductBloc>().add(FetchCategoriesTreeEvent());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
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
                      'Select a Category',
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
                      if (state is AdminCategoriesLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2ED573),
                          ),
                        );
                      }
                      if (state is AdminCategoriesLoaded) {
                        if (state.categories.isEmpty) {
                          return const Center(
                            child: Text(
                              'No categories found.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: state.categories.length,
                          itemBuilder: (context, index) {
                            final category = state.categories[index];
                            return _buildCategoryListItem(category);
                          },
                        );
                      }
                      if (state is AdminCategoriesError) {
                        return Center(
                          child: Text(
                            'Error: ${state.message}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
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

  Widget _buildCategoryListItem(dynamic category) {
    final name = _extractCategoryName(category);
    final description = _extractCategoryDescription(category);
    final linkTarget = _extractCategorySlugOrId(category);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _selectLink('/products/category/$linkTarget');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.category,
                color: Colors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
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
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Iconsax.arrow_right_3, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showCustomLinkDialog() {
    final controller = TextEditingController(text: _actionLinkController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Custom Link'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '/custom/path or https://...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ED573),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _selectLink(controller.text.trim());
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
                      _buildActionLinkSelector(),
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
