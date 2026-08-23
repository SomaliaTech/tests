import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:http_parser/http_parser.dart'; // ✅ Add this import
// Import BLoCs for product/category selection
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_state.dart';

class BroadcastNotificationScreen extends StatefulWidget {
  const BroadcastNotificationScreen({super.key});

  @override
  State<BroadcastNotificationScreen> createState() =>
      _BroadcastNotificationScreenState();
}

class _BroadcastNotificationScreenState
    extends State<BroadcastNotificationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _buttonTextController = TextEditingController();
  final _actionLinkController = TextEditingController();

  bool _isLoading = false;
  String _targetAudience = 'all_users';
  bool _sendPushNotification = true;
  bool _scheduleForLater = false;
  DateTime? _scheduledTime;

  // ✅ Image handling state
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  final sl = GetIt.instance;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _buttonTextController.dispose();
    _actionLinkController.dispose();
    super.dispose();
  }

  // ==========================================
  // IMAGE HANDLING
  // ==========================================

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // ==========================================
  // BROADCAST NOTIFICATION
  // ==========================================

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final storage = sl<StorageService>();
      final token = await storage.getAuthToken();

      final actionLink = _actionLinkController.text.trim();
      final buttonText = _buttonTextController.text.trim();

      if (_selectedImage != null) {
        // ✅ Use MultipartRequest when an image is attached
        final uri = Uri.parse(
          '${ApiConstants.baseUrl}/notifications/broadcast',
        );
        final request = http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['title'] = _titleController.text.trim()
          ..fields['message'] = _messageController.text.trim()
          ..fields['actionText'] = buttonText.isEmpty ? 'View' : buttonText
          ..fields['targetAudience'] = _targetAudience
          ..fields['sendPush'] = _sendPushNotification.toString();

        if (actionLink.isNotEmpty) {
          request.fields['actionLink'] = actionLink;
        }

        if (_scheduleForLater && _scheduledTime != null) {
          request.fields['scheduledAt'] = _scheduledTime!.toIso8601String();
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
            filename: 'broadcast_image.jpg',
            contentType: MediaType(
              'image',
              'jpeg',
            ), // ✅ Explicitly force image/jpeg
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final recipientsCount = data['recipientsCount'] ?? 0;
          if (mounted) {
            HapticFeedback.heavyImpact();
            _showSuccessToast(
              _scheduleForLater
                  ? 'Notification scheduled for ${_formatDateTime(_scheduledTime!)}'
                  : 'Broadcast sent to $recipientsCount users!',
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception('Failed: ${response.body}');
        }
      } else {
        // ✅ Standard JSON request when no image
        final body = {
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'actionText': buttonText.isEmpty ? 'View' : buttonText,
          'actionLink': actionLink.isEmpty ? null : actionLink,
          'targetAudience': _targetAudience,
          'sendPush': _sendPushNotification,
          if (_scheduleForLater && _scheduledTime != null)
            'scheduledAt': _scheduledTime!.toIso8601String(),
        };

        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/notifications/broadcast'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(body),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final recipientsCount = data['recipientsCount'] ?? 0;
          if (mounted) {
            HapticFeedback.heavyImpact();
            _showSuccessToast(
              _scheduleForLater
                  ? 'Notification scheduled for ${_formatDateTime(_scheduledTime!)}'
                  : 'Broadcast sent to $recipientsCount users!',
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception('Failed: ${response.body}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorToast('Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.send_2, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirm Broadcast',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleController.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _messageController.text,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildConfirmationRow(
              icon: Iconsax.user,
              label: 'Target',
              value: _getTargetAudienceLabel(_targetAudience),
            ),
            const SizedBox(height: 8),
            _buildConfirmationRow(
              icon: Iconsax.notification,
              label: 'Push Notification',
              value: _sendPushNotification ? 'Yes' : 'No',
            ),
            if (_scheduleForLater && _scheduledTime != null) ...[
              const SizedBox(height: 8),
              _buildConfirmationRow(
                icon: Iconsax.clock,
                label: 'Scheduled',
                value: _formatDateTime(_scheduledTime!),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Broadcast Now',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _getTargetAudienceLabel(String target) {
    switch (target) {
      case 'all_users':
        return 'All Users';
      case 'admins_only':
        return 'Admins Only';
      case 'inactive_users':
        return 'Inactive Users (7+ days)';
      case 'active_users':
        return 'Active Users (last 7 days)';
      case 'premium_users':
        return 'Premium Users';
      default:
        return 'All Users';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showSuccessToast(String message) {
    toastification.show(
      context: context,
      title: Text(message),
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  void _showErrorToast(String message) {
    toastification.show(
      context: context,
      title: Text(message),
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 4),
    );
  }

  // ==========================================
  // SCHEDULE PICKER
  // ==========================================

  Future<void> _selectScheduledTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C5CE7),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF6C5CE7),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
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
          'Button Destination (Optional)',
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
              border: Border.all(
                color: link.isEmpty
                    ? const Color(0xFFE5E7EB)
                    : displayColor.withOpacity(0.5),
                width: link.isEmpty ? 1 : 1.5,
              ),
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
              backgroundColor: const Color(0xFF6C5CE7),
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
  // PRODUCT PICKER
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
                            color: Color(0xFF6C5CE7),
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
    // Helper to extract image safely
    String? imageUrl;
    try {
      if (product.imageUrl != null)
        imageUrl = product.imageUrl.toString();
      else if (product.mainImage != null)
        imageUrl = product.mainImage.toString();
      else if (product.images != null && product.images.isNotEmpty) {
        final first = product.images.first;
        if (first is String)
          imageUrl = first;
        else if (first.url != null)
          imageUrl = first.url.toString();
      }
    } catch (_) {}

    String name = 'Unknown Product';
    try {
      name = product.name ?? 'Unknown Product';
    } catch (_) {}

    String price = '\$0.00';
    try {
      price = '\$${(product.price as num).toStringAsFixed(2)}';
    } catch (_) {}

    String linkTarget = '';
    try {
      if (product.slug != null && product.slug.toString().isNotEmpty)
        linkTarget = product.slug;
      else
        linkTarget = product.id;
    } catch (_) {}

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
                    price,
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
  // CATEGORY PICKER
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
                            color: Color(0xFF6C5CE7),
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
    String name = 'Unknown Category';
    try {
      name = category.name ?? 'Unknown Category';
    } catch (_) {}

    String linkTarget = '';
    try {
      if (category.slug != null && category.slug.toString().isNotEmpty)
        linkTarget = category.slug;
      else
        linkTarget = category.id;
    } catch (_) {}

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
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const Icon(Iconsax.arrow_right_3, color: Colors.grey),
          ],
        ),
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
          'Broadcast Notification',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeroHeader(),
            const SizedBox(height: 24),

            _buildSectionCard(
              title: 'Notification Content',
              icon: Iconsax.document_text,
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
              ),
              children: [
                _buildInputField(
                  controller: _titleController,
                  label: 'Title *',
                  hint: 'e.g., Flash Sale Starts Now!',
                  icon: Iconsax.notification,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _messageController,
                  label: 'Message *',
                  hint: 'Write your promotional message here...',
                  icon: Iconsax.message_text,
                  maxLines: 4,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Message is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // ✅ NEW: Image Picker UI
                _buildImagePicker(),
                const SizedBox(height: 16),

                _buildInputField(
                  controller: _buttonTextController,
                  label: 'Button Text (Optional)',
                  hint: 'e.g., Shop Now',
                  icon: Iconsax.mouse,
                ),
                const SizedBox(height: 16),
                _buildActionLinkSelector(),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Target Audience',
              icon: Iconsax.user_tick,
              gradient: const LinearGradient(
                colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
              ),
              children: [_buildAudienceSelector()],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Delivery Options',
              icon: Iconsax.send_2,
              gradient: const LinearGradient(
                colors: [Color(0xFFFDCB6E), Color(0xFFE17055)],
              ),
              children: [
                _buildSwitch(
                  label: 'Send Push Notification',
                  subtitle: 'Deliver to user devices',
                  value: _sendPushNotification,
                  onChanged: (v) => setState(() => _sendPushNotification = v),
                  icon: Iconsax.notification_1,
                  color: const Color(0xFF6C5CE7),
                ),
                const SizedBox(height: 12),
                _buildSwitch(
                  label: 'Schedule for Later',
                  subtitle: _scheduledTime != null
                      ? 'Scheduled: ${_formatDateTime(_scheduledTime!)}'
                      : 'Send at a specific time',
                  value: _scheduleForLater,
                  onChanged: (v) {
                    setState(() => _scheduleForLater = v);
                    if (v && _scheduledTime == null) {
                      _selectScheduledTime();
                    }
                  },
                  icon: Iconsax.clock,
                  color: const Color(0xFF00B894),
                ),
                if (_scheduleForLater && _scheduledTime != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _selectScheduledTime,
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
                              color: const Color(0xFF00B894).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Iconsax.calendar,
                              color: Color(0xFF00B894),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tap to change schedule',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(_scheduledTime!),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Iconsax.arrow_right_3, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // ✅ Updated Preview Card to show image
            _buildPreviewCard(),
            const SizedBox(height: 24),

            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendBroadcast,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Iconsax.send_2),
                label: Text(
                  _isLoading
                      ? 'Sending...'
                      : _scheduleForLater
                      ? 'Schedule Broadcast'
                      : 'Broadcast Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF6C5CE7).withOpacity(0.4),
                  minimumSize: const Size(
                    double.infinity,
                    56,
                  ), // Ensures fixed size
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // NEW: IMAGE PICKER WIDGET
  // ==========================================
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Image (Optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedImage != null
                    ? const Color(0xFF6C5CE7)
                    : const Color(0xFFE5E7EB),
                width: _selectedImage != null ? 2 : 1,
              ),
            ),
            child: _selectedImage != null
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
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.gallery_add,
                          color: Color(0xFF6C5CE7),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to add an image',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // UPDATED: PREVIEW CARD WITH IMAGE
  // ==========================================
  Widget _buildPreviewCard() {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final buttonText = _buttonTextController.text.trim();

    if (title.isEmpty && message.isEmpty && _selectedImage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.eye,
                  color: Color(0xFF6C5CE7),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Preview',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ Show image in preview if selected
          if (_selectedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Your Title Here' : title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (buttonText.isNotEmpty) ...[
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
                      buttonText,
                      style: const TextStyle(
                        color: Color(0xFF6C5CE7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE), Color(0xFFFD79A8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Iconsax.textalign_left,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Broadcast to All',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Reach your entire user base instantly',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceSelector() {
    final audiences = [
      {
        'id': 'all_users',
        'label': 'All Users',
        'icon': Iconsax.profile_2user,
        'color': Colors.blue,
      },
      {
        'id': 'active_users',
        'label': 'Active Users',
        'icon': Iconsax.user_tick,
        'color': Colors.green,
      },
      {
        'id': 'inactive_users',
        'label': 'Inactive (7+ days)',
        'icon': Iconsax.user_minus,
        'color': Colors.orange,
      },
      {
        'id': 'admins_only',
        'label': 'Admins Only',
        'icon': Iconsax.shield_tick,
        'color': Colors.purple,
      },
    ];

    return Column(
      children: audiences.map((audience) {
        final isSelected = _targetAudience == audience['id'];
        final color = audience['color'] as Color;
        final icon = audience['icon'] as IconData;
        final label = audience['label'] as String;

        return GestureDetector(
          onTap: () =>
              setState(() => _targetAudience = audience['id'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.1)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? color : const Color(0xFF1F2937),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.tick_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
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
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7), size: 20),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6C5CE7),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.05) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: color,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
