// lib/features/admin/presentation/screens/admin_product_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/core/services/permission_service.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_state.dart';
import 'package:mobile/features/admin/presentation/screens/edit_product_screen.dart';
import 'package:toastification/toastification.dart';

class AdminProductDetailsScreen extends StatefulWidget {
  final String productId;

  const AdminProductDetailsScreen({super.key, required this.productId});

  @override
  State<AdminProductDetailsScreen> createState() =>
      _AdminProductDetailsScreenState();
}

class _AdminProductDetailsScreenState extends State<AdminProductDetailsScreen> {
  AdminProductEntity? _cachedProduct;
  bool _isInitialLoad = true;

  // ✅ Permission state
  bool _canUpdate = false;
  bool _canDelete = false;
  bool _permissionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _loadPermissions();
  }

  // ✅ Load permissions
  Future<void> _loadPermissions() async {
    try {
      final storageService = sl<StorageService>();
      final permissionService = GetIt.instance<PermissionService>();

      final isSuper = await storageService.getIsSuperAdmin();
      final perms = await permissionService.loadPermissions(
        forceRefresh: false,
      );

      bool has(String p) {
        if (isSuper) return true;
        if (perms.contains('*')) return true;
        if (perms.contains(p)) return true;
        final module = p.split(':').first;
        return perms.contains('$module:manage');
      }

      if (!mounted) return;

      setState(() {
        _canUpdate = has('product:update');
        _canDelete = has('product:delete');
        _permissionsLoaded = true;
      });

      debugPrint(
        '🔐 [ProductDetails] canUpdate: $_canUpdate, canDelete: $_canDelete',
      );
    } catch (e) {
      debugPrint('❌ [ProductDetails] Permission load failed: $e');
      if (!mounted) return;
      setState(() {
        _permissionsLoaded = true;
      });
    }
  }

  void _loadProduct() {
    debugPrint('🔄 [AdminProductDetails] Loading product: ${widget.productId}');
    context.read<AdminProductBloc>().add(
      FetchAdminProductByIdEvent(widget.productId),
    );
  }

  void _showToast(String message, bool isSuccess) {
    toastification.show(
      context: context,
      title: Text(message),
      type: isSuccess ? ToastificationType.success : ToastificationType.error,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 3),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      foregroundColor: Colors.white,
      icon: Icon(
        isSuccess ? Iconsax.tick_circle : Iconsax.warning_2,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // ✅ Only show edit in app bar if user has update permission
          if (_canUpdate)
            IconButton(
              icon: const Icon(Iconsax.edit, color: AppTheme.primaryColor),
              onPressed: _navigateToEdit,
            ),
        ],
      ),
      body: BlocConsumer<AdminProductBloc, AdminProductState>(
        listener: (context, state) {
          debugPrint('📢 [AdminProductDetails] State: $state');

          if (state is AdminProductDetailsLoaded) {
            setState(() {
              _cachedProduct = state.product;
              _isInitialLoad = false;
            });
          } else if (state is AdminProductOperationSuccess) {
            if (state.message.contains('deleted')) {
              _showToast(state.message, true);
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  Navigator.pop(context, true);
                }
              });
            }
          } else if (state is AdminProductsError) {
            if (_cachedProduct == null) {
              _showToast(state.message, false);
            }
          }
        },
        builder: (context, state) {
          final isLoading =
              state is AdminProductDetailsLoading ||
              (state is! AdminProductDetailsLoaded &&
                  state is! AdminProductDetailsError);

          final product = state is AdminProductDetailsLoaded
              ? state.product
              : _cachedProduct;

          if (isLoading && _cachedProduct == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (state is AdminProductDetailsError && _cachedProduct == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.warning_2, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load product',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (product != null) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadProduct();
                await Future.delayed(const Duration(milliseconds: 800));
              },
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGallery(product.images),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Product Information',
                      icon: Iconsax.info_circle,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (product.categoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                product.categoryName!,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: product.isActive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  product.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: product.isActive
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Stock', '${product.stock} units'),
                          if (product.brand != null)
                            _buildInfoRow('Brand', product.brand!),
                          if (product.tags != null)
                            _buildInfoRow('Tags', product.tags!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      _buildSectionCard(
                        title: 'Description',
                        icon: Iconsax.document_text,
                        child: Text(
                          product.description!,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (product.variants.isNotEmpty) ...[
                      _buildSectionCard(
                        title: 'Variants (${product.variants.length})',
                        icon: Iconsax.box_1,
                        child: Column(
                          children: product.variants
                              .map((variant) => _buildVariantTile(variant))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ✅ PERMISSION-BASED ACTION BUTTONS
                    if (_canUpdate || _canDelete) ...[
                      _buildActionButtons(product),
                    ] else ...[
                      // ✅ Show read-only info box if no permissions
                      _buildReadOnlyInfoBox(),
                    ],
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ✅ Permission-based action buttons
  Widget _buildActionButtons(AdminProductEntity product) {
    // If both permissions exist, show side by side
    if (_canUpdate && _canDelete) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _navigateToEdit,
              icon: const Icon(Iconsax.edit_2),
              label: const Text('Edit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showDeleteConfirmation(product),
              icon: const Icon(Iconsax.trash, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // If only update permission
    if (_canUpdate) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _navigateToEdit,
          icon: const Icon(Iconsax.edit_2),
          label: const Text('Edit Product'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      );
    }

    // If only delete permission
    if (_canDelete) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showDeleteConfirmation(product),
          icon: const Icon(Iconsax.trash, color: Colors.red),
          label: const Text(
            'Delete Product',
            style: TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ✅ Read-only info box when user has no edit/delete permission
  Widget _buildReadOnlyInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.info_circle, color: Colors.blue[400], size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You have view-only access to this product.',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit() async {
    debugPrint('📝 [AdminProductDetails] Navigating to edit screen');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(productId: widget.productId),
      ),
    );

    debugPrint(
      '↩️ [AdminProductDetails] Returned from edit with result: $result',
    );

    if (result == true && mounted) {
      debugPrint('🔄 [AdminProductDetails] Reloading product after edit');
      _loadProduct();
    }
  }

  Widget _buildImageGallery(List<AdminProductImageEntity> images) {
    if (images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(Iconsax.image, size: 60, color: Colors.grey[400]),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              images[index].url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: Icon(Iconsax.image, size: 60, color: Colors.grey[400]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantTile(AdminProductVariantEntity variant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (variant.colorName != null)
                  Text(
                    'Color: ${variant.colorName}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (variant.sizeName != null)
                  Text(
                    'Size: ${variant.sizeName}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (variant.sku != null)
                  Text(
                    'SKU: ${variant.sku}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (variant.price != null)
                Text(
                  '\$${variant.price!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                'Stock: ${variant.stock}',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(AdminProductEntity product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.warning_2, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Product',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminProductBloc>().add(
                DeleteAdminProductEvent(product.id),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
