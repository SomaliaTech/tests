import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';
import 'package:mobile/features/admin/domain/entities/color_entity.dart';
import 'package:mobile/features/admin/domain/entities/size_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_state.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _tagsController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  // Existing images from backend
  final List<AdminProductImageEntity> _existingImages = [];
  // New images to upload
  final List<File> _newImages = [];
  // Track deleted image IDs
  final List<String> _deletedImageIds = [];

  // Existing variants from backend
  final List<AdminProductVariantEntity> _existingVariants = [];
  // New variants to add
  final List<Map<String, dynamic>> _newVariants = [];

  AdminCategoryEntity? _selectedCategory;
  AdminCategoryEntity? _selectedSubcategory;
  bool _isActive = true;
  bool _isLoadingProduct = true;

  @override
  void initState() {
    super.initState();
    context.read<AdminProductBloc>().add(FetchCategoriesTreeEvent());
    context.read<AdminProductBloc>().add(FetchColorsEvent());
    context.read<AdminProductBloc>().add(FetchSizesEvent());
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    context.read<AdminProductBloc>().add(
      FetchAdminProductByIdEvent(widget.productId),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _populateFields(AdminProductEntity product) {
    _nameController.text = product.name;
    _descriptionController.text = product.description ?? '';
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();
    _brandController.text = product.brand ?? '';
    _tagsController.text = product.tags ?? '';
    _isActive = product.isActive;
    _existingImages.addAll(product.images);
    _existingVariants.addAll(product.variants);

    // Set selected category
    if (product.categoryId != null) {
      // We'll set this when categories are loaded
    }
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _newImages.addAll(pickedFiles.map((f) => File(f.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
    }
  }

  void _removeExistingImage(int index) {
    final image = _existingImages[index];
    setState(() {
      _existingImages.removeAt(index);
      _deletedImageIds.add(image.id);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _showAddVariantDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddVariantDialog(
        onAdd: (variant) {
          setState(() {
            _newVariants.add(variant);
          });
        },
      ),
    );
  }

  void _removeExistingVariant(int index) {
    setState(() {
      _existingVariants.removeAt(index);
    });
  }

  void _removeNewVariant(int index) {
    setState(() {
      _newVariants.removeAt(index);
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final categoryId = _selectedSubcategory?.id ?? _selectedCategory?.id;

    final updateData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text),
      'stock': int.parse(_stockController.text),
      'categoryId': categoryId,
      'brand': _brandController.text.trim(),
      'tags': _tagsController.text.trim(),
      'isActive': _isActive,
    };

    context.read<AdminProductBloc>().add(
      UpdateAdminProductEvent(
        productId: widget.productId,
        updateData: updateData,
        newImages: _newImages,
        deletedImageIds: _deletedImageIds,
        newVariants: _newVariants,
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
          icon: const Icon(Iconsax.arrow_left_2, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Product',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AdminProductBloc, AdminProductState>(
        listener: (context, state) {
          if (state is AdminProductDetailsLoaded && _isLoadingProduct) {
            _populateFields(state.product);

            // Set category after loading
            context.read<AdminProductBloc>().add(FetchCategoriesTreeEvent());

            setState(() {
              _isLoadingProduct = false;
            });
          } else if (state is AdminProductOperationSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
          } else if (state is AdminProductsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (_isLoadingProduct) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Images Section
                  _buildSectionCard(
                    title: 'Product Images',
                    icon: Iconsax.image,
                    child: _buildImageUploadSection(),
                  ),
                  const SizedBox(height: 16),

                  // Basic Information
                  _buildSectionCard(
                    title: 'Basic Information',
                    icon: Iconsax.info_circle,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Product Name',
                          hint: 'Enter product name',
                          icon: Iconsax.box_1,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Product name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'Enter product description',
                          icon: Iconsax.document_text,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _priceController,
                                label: 'Price',
                                hint: '0.00',
                                icon: Iconsax.money_tick,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Price is required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _stockController,
                                label: 'Stock',
                                hint: '0',
                                icon: Iconsax.box,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Stock is required';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Invalid stock';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Selection
                  _buildSectionCard(
                    title: 'Category',
                    icon: Iconsax.category,
                    child: BlocBuilder<AdminProductBloc, AdminProductState>(
                      buildWhen: (prev, current) =>
                          current is AdminCategoriesLoading ||
                          current is AdminCategoriesLoaded,
                      builder: (context, state) {
                        if (state is AdminCategoriesLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          );
                        }

                        if (state is AdminCategoriesLoaded) {
                          return Column(
                            children: [
                              _buildCategoryDropdown(
                                label: 'Parent Category',
                                categories: state.categories,
                                selectedCategory: _selectedCategory,
                                onChanged: (category) {
                                  setState(() {
                                    _selectedCategory = category;
                                    _selectedSubcategory = null;
                                  });
                                },
                              ),
                              if (_selectedCategory != null &&
                                  _selectedCategory!.children.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildCategoryDropdown(
                                  label: 'Subcategory',
                                  categories: _selectedCategory!.children,
                                  selectedCategory: _selectedSubcategory,
                                  onChanged: (category) {
                                    setState(() {
                                      _selectedSubcategory = category;
                                    });
                                  },
                                ),
                              ],
                            ],
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Variants Section
                  _buildSectionCard(
                    title:
                        'Variants (${_existingVariants.length + _newVariants.length})',
                    icon: Iconsax.box_1,
                    child: _buildVariantsSection(),
                  ),
                  const SizedBox(height: 16),

                  // Additional Information
                  _buildSectionCard(
                    title: 'Additional Information',
                    icon: Iconsax.setting_2,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _brandController,
                          label: 'Brand',
                          hint: 'Enter brand name',
                          icon: Iconsax.tag,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _tagsController,
                          label: 'Tags',
                          hint: 'Enter tags (comma-separated)',
                          icon: Iconsax.hashtag,
                        ),
                        const SizedBox(height: 16),
                        _buildSwitchTile(
                          label: 'Active',
                          value: _isActive,
                          onChanged: (value) {
                            setState(() => _isActive = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageUploadSection() {
    final totalImages = _existingImages.length + _newImages.length;

    return Column(
      children: [
        if (totalImages == 0)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.camera, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to upload images',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: totalImages + 1,
            itemBuilder: (context, index) {
              if (index == totalImages) {
                return GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Icon(
                        Iconsax.add,
                        color: Colors.grey[500],
                        size: 30,
                      ),
                    ),
                  ),
                );
              }

              // Existing images
              if (index < _existingImages.length) {
                final image = _existingImages[index];
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(image.url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeExistingImage(index),
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
                  ],
                );
              }

              // New images
              final newIndex = index - _existingImages.length;
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_newImages[newIndex]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeNewImage(newIndex),
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
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildVariantsSection() {
    final totalVariants = _existingVariants.length + _newVariants.length;

    return Column(
      children: [
        if (totalVariants == 0)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No variants added yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          )
        else ...[
          // Existing variants
          ...List.generate(_existingVariants.length, (index) {
            final variant = _existingVariants[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${variant.colorName ?? ''} / ${variant.sizeName ?? ''}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${variant.sku ?? '-'} • Stock: ${variant.stock} • \$${variant.price?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Iconsax.trash,
                      color: Colors.red,
                      size: 18,
                    ),
                    onPressed: () => _removeExistingVariant(index),
                  ),
                ],
              ),
            );
          }),
          // New variants
          ...List.generate(_newVariants.length, (index) {
            final variant = _newVariants[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${variant['colorName'] ?? ''} / ${variant['sizeName'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${variant['sku'] ?? '-'} • Stock: ${variant['stock']} • \$${variant['price']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Iconsax.trash,
                      color: Colors.red,
                      size: 18,
                    ),
                    onPressed: () => _removeNewVariant(index),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAddVariantDialog,
            icon: const Icon(Iconsax.add, color: AppTheme.primaryColor),
            label: const Text(
              'Add Variant',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<AdminProductBloc, AdminProductState>(
      buildWhen: (prev, current) => current is AdminProductCreating,
      builder: (context, state) {
        final isUpdating = state is AdminProductCreating;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isUpdating ? null : _submitForm,
            icon: isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Iconsax.edit),
            label: Text(
              isUpdating
                  ? '${state.step.replaceAll('_', ' ').toUpperCase()} (${state.current}/${state.total})'
                  : 'Update Product',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        );
      },
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
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
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown({
    required String label,
    required List<AdminCategoryEntity> categories,
    required AdminCategoryEntity? selectedCategory,
    required ValueChanged<AdminCategoryEntity?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AdminCategoryEntity>(
              value: selectedCategory,
              hint: Text(
                'Select $label',
                style: TextStyle(color: Colors.grey[400]),
              ),
              isExpanded: true,
              icon: const Icon(Iconsax.arrow_down_2, color: Colors.grey),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category.name,
                    style: const TextStyle(color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

// Reuse the _AddVariantDialog from AddProductScreen
class _AddVariantDialog extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAdd;

  const _AddVariantDialog({required this.onAdd});

  @override
  State<_AddVariantDialog> createState() => _AddVariantDialogState();
}

class _AddVariantDialogState extends State<_AddVariantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _skuController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();

  ColorEntity? _selectedColor;
  SizeEntity? _selectedSize;

  @override
  void dispose() {
    _skuController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedColor == null || _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select color and size')),
      );
      return;
    }

    final variant = {
      'colorId': _selectedColor!.id,
      'colorName': _selectedColor!.name,
      'sizeId': _selectedSize!.id,
      'sizeName': _selectedSize!.name,
      'sku': _skuController.text.trim(),
      'stock': int.parse(_stockController.text),
      'price': double.parse(_priceController.text),
    };

    widget.onAdd(variant);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Variant'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlocBuilder<AdminProductBloc, AdminProductState>(
                buildWhen: (prev, current) =>
                    current is AdminColorsLoading ||
                    current is AdminColorsLoaded,
                builder: (context, state) {
                  if (state is AdminColorsLoading) {
                    return const CircularProgressIndicator();
                  }
                  if (state is AdminColorsLoaded) {
                    return _buildDropdown<ColorEntity>(
                      label: 'Color',
                      value: _selectedColor,
                      items: state.colors,
                      itemLabel: (c) => c.name,
                      onChanged: (c) => setState(() => _selectedColor = c),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 12),
              BlocBuilder<AdminProductBloc, AdminProductState>(
                buildWhen: (prev, current) =>
                    current is AdminSizesLoading || current is AdminSizesLoaded,
                builder: (context, state) {
                  if (state is AdminSizesLoading) {
                    return const CircularProgressIndicator();
                  }
                  if (state is AdminSizesLoaded) {
                    return _buildDropdown<SizeEntity>(
                      label: 'Size',
                      value: _selectedSize,
                      items: state.sizes,
                      itemLabel: (s) => '${s.name} (${s.value})',
                      onChanged: (s) => setState(() => _selectedSize = s),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 12),
              _buildDialogTextField(
                controller: _skuController,
                label: 'SKU',
                hint: 'e.g., PROD-RED-M',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDialogTextField(
                      controller: _stockController,
                      label: 'Stock',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDialogTextField(
                      controller: _priceController,
                      label: 'Price',
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(itemLabel(item)));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: validator,
    );
  }
}
