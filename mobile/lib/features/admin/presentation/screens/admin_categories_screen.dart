// lib/features/admin/presentation/screens/admin_categories_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/core/utils/toast_helper.dart';
import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_category/admin_category_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_category/admin_category_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_category/admin_category_state.dart';
import 'package:mobile/features/admin/presentation/widgets/transfer_products_dialog.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  bool _isInitialLoad = true;
  bool _showSuccessMessage = false;
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    // ✅ Load only once on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminCategoryBloc>().add(FetchCategoriesTreeEvent());
    });
  }

  void _showAddCategoryDialog({AdminCategoryEntity? parentCategory}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditCategoryDialog(
        parentCategory: parentCategory,
        onSubmit: (data) {
          context.read<AdminCategoryBloc>().add(CreateCategoryEvent(data));
          // ✅ Show success after dialog closes
          _successMessage = parentCategory != null
              ? 'Subcategory created successfully'
              : 'Category created successfully';
        },
      ),
    );
  }

  void _showEditCategoryDialog(AdminCategoryEntity category) {
    showDialog(
      context: context,
      builder: (context) => _AddEditCategoryDialog(
        category: category,
        onSubmit: (data) {
          context.read<AdminCategoryBloc>().add(
            UpdateCategoryEvent(category.id, data),
          );
          _successMessage = 'Category updated successfully';
        },
      ),
    );
  }

  void _showDeleteConfirmation(AdminCategoryEntity category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminCategoryBloc>().add(
                DeleteCategoryEvent(category.id),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    final state = context.read<AdminCategoryBloc>().state;
    if (state is AdminCategoriesLoaded) {
      final category = _findCategoryById(state.categories, categoryId);
      return category?.name ?? 'Unknown';
    }
    return 'Unknown';
  }

  AdminCategoryEntity? _findCategoryById(
    List<AdminCategoryEntity> categories,
    String id,
  ) {
    for (final category in categories) {
      if (category.id == id) return category;
      final found = _findCategoryById(category.children, id);
      if (found != null) return found;
    }
    return null;
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
          'Categories',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: Colors.black87),
            onPressed: () {
              _isInitialLoad = true;
              context.read<AdminCategoryBloc>().add(FetchCategoriesTreeEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<AdminCategoryBloc, AdminCategoryState>(
        // In your AdminCategoriesScreen, replace the BlocConsumer listener with this:
        listener: (context, state) {
          if (state is AdminCategoriesLoaded) {
            setState(() => _isInitialLoad = false);
          }

          if (state is AdminCategoryOperationSuccess) {
            ToastHelper.showSuccess(context, state.message);
          }

          if (state is AdminCategoriesError) {
            setState(() => _isInitialLoad = false);
            if (_isInitialLoad) {
              ToastHelper.showError(context, state.message);
            }
          }

          if (state is AdminCategoryHasProducts) {
            // ✅ Show transfer dialog WITHOUT setting loading state
            showDialog(
              context: context,
              barrierDismissible: false, // ✅ Prevent dismiss by tapping outside
              builder: (_) => TransferProductsDialog(
                categoryId: state.categoryId,
                categoryName: _getCategoryName(state.categoryId),
              ),
            );
          }
        },
        builder: (context, state) {
          // ✅ Initial loading
          if (state is AdminCategoriesLoading && _isInitialLoad) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          // ✅ Error on first load
          if (state is AdminCategoriesError && _isInitialLoad) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.warning_2,
                        size: 48,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _isInitialLoad = true);
                        context.read<AdminCategoryBloc>().add(
                          FetchCategoriesTreeEvent(),
                        );
                      },
                      icon: const Icon(Iconsax.refresh, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ✅ Show loaded categories
          if (state is AdminCategoriesLoaded) {
            if (state.categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.category, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No categories yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first category to get started',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    return _buildCategoryCard(category, 0);
                  },
                ),
                // ✅ Show loading indicator at bottom during operations
                if (state is AdminCategoriesLoading && !_isInitialLoad)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }

          // ✅ Fallback
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: const Text(
          'Add Category',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(AdminCategoryEntity category, int level) {
    return Container(
      margin: EdgeInsets.only(bottom: 12, left: level * 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildCategoryIcon(category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (category.description != null &&
                          category.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Slug: ${category.slug}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      if (category.children.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${category.children.length} subcategor${category.children.length == 1 ? 'y' : 'ies'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'add_subcategory':
                        _showAddCategoryDialog(parentCategory: category);
                      case 'edit':
                        _showEditCategoryDialog(category);
                      case 'delete':
                        _showDeleteConfirmation(category);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'add_subcategory',
                      child: Row(
                        children: [
                          Icon(Iconsax.add_circle, size: 18),
                          SizedBox(width: 8),
                          Text('Add Subcategory'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Iconsax.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Iconsax.trash, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (category.children.isNotEmpty) ...[
            const Divider(height: 1),
            ...category.children.map(
              (child) => _buildCategoryCard(child, level + 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(AdminCategoryEntity category) {
    if (category.iconUrl != null && category.iconUrl!.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: NetworkImage(category.iconUrl!),
            fit: BoxFit.cover,
          ),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Iconsax.category,
        color: AppTheme.primaryColor,
        size: 20,
      ),
    );
  }
}

// ==========================================
// _AddEditCategoryDialog - KEEP EXACTLY AS IS
// ==========================================
class _AddEditCategoryDialog extends StatefulWidget {
  final AdminCategoryEntity? category;
  final AdminCategoryEntity? parentCategory;
  final void Function(Map<String, dynamic>) onSubmit;

  const _AddEditCategoryDialog({
    this.category,
    this.parentCategory,
    required this.onSubmit,
  });

  @override
  State<_AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<_AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedIcon;
  String? _existingIconUrl;
  bool _isSubmitting = false;

  bool get isEditing => widget.category != null;
  bool get _isSubcategory {
    if (widget.parentCategory != null) return true;
    if (isEditing && widget.category!.parentId != null) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.category!.name;
      _slugController.text = widget.category!.slug;
      _descriptionController.text = widget.category!.description ?? '';
      _existingIconUrl = widget.category!.iconUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedIcon = File(pickedFile.path);
          _existingIconUrl = null;
        });
      }
    } catch (e) {
      ToastHelper.showError(context, 'Failed to pick image: $e');
    }
  }

  void _removeIcon() => setState(() {
    _selectedIcon = null;
    _existingIconUrl = null;
  });

  Future<String?> _convertToBase64() async {
    if (_selectedIcon == null) return null;
    try {
      final bytes = await _selectedIcon!.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (e) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final data = {
        'name': _nameController.text.trim(),
        'slug': _slugController.text.trim(),
        'description': _descriptionController.text.trim(),
      };
      if (!isEditing && widget.parentCategory != null)
        data['parentId'] = widget.parentCategory!.id;
      if (!_isSubcategory && _selectedIcon != null) {
        final base64Image = await _convertToBase64();
        if (base64Image != null) data['iconBase64'] = base64Image;
      }
      widget.onSubmit(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) ToastHelper.showError(context, 'Failed to submit: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing ? Iconsax.edit : Iconsax.add_circle,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? 'Edit Category'
                                : (_isSubcategory
                                      ? 'Add Subcategory'
                                      : 'Add Category'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (widget.parentCategory != null)
                            Text(
                              'Under: ${widget.parentCategory!.name}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (!_isSubcategory) ...[
                  _buildIconPicker(),
                  const SizedBox(height: 20),
                ],
                _buildTextField(
                  controller: _nameController,
                  label: _isSubcategory ? 'Subcategory Name' : 'Category Name',
                  hint: _isSubcategory
                      ? 'Enter subcategory name'
                      : 'Enter category name',
                  icon: Iconsax.category,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                  onChanged: (value) {
                    if (!isEditing)
                      setState(
                        () => _slugController.text = value
                            .toLowerCase()
                            .replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
                      );
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _slugController,
                  label: 'Slug',
                  hint: 'category-slug',
                  icon: Iconsax.link_21,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Slug is required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Enter description (optional)',
                  icon: Iconsax.document_text,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEditing
                                    ? 'Update'
                                    : (_isSubcategory
                                          ? 'Create Subcategory'
                                          : 'Create Category'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconPicker() {
    final hasIcon = _selectedIcon != null || _existingIconUrl != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category Icon',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Optional - Upload an icon image for this category',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickIcon,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasIcon
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                width: hasIcon ? 2 : 1,
              ),
            ),
            child: hasIcon
                ? Stack(
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _selectedIcon != null
                              ? Image.file(
                                  _selectedIcon!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  _existingIconUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Iconsax.image,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _removeIcon,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Iconsax.close_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Tap to change',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
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
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.gallery_add,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload icon',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: validator,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
