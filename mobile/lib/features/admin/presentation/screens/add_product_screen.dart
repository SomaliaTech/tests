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

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _tagsController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];

  AdminCategoryEntity? _selectedCategory;
  AdminCategoryEntity? _selectedSubcategory;
  bool _isActive = true;

  // Variants
  final List<Map<String, dynamic>> _variants = [];

  @override
  void initState() {
    super.initState();
    context.read<AdminProductBloc>().add(FetchCategoriesTreeEvent());
    context.read<AdminProductBloc>().add(FetchColorsEvent());
    context.read<AdminProductBloc>().add(FetchSizesEvent());
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

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((f) => File(f.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showAddVariantDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddVariantDialog(
        onAdd: (variant) {
          setState(() {
            _variants.add(variant);
          });
        },
      ),
    );
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final categoryId = _selectedSubcategory?.id ?? _selectedCategory!.id;

    final productData = {
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
      CreateAdminProductEvent(
        productData: productData,
        images: _selectedImages,
        variants: _variants,
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
          'Add Product',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<AdminProductBloc, AdminProductState>(
        listener: (context, state) {
          if (state is AdminProductOperationSuccess) {
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
        child: SingleChildScrollView(
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
                  title: 'Variants (${_variants.length})',
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
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        if (_selectedImages.isEmpty)
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
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
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

              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
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
    return Column(
      children: [
        if (_variants.isEmpty)
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
        else
          ...List.generate(_variants.length, (index) {
            final variant = _variants[index];
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
                    onPressed: () => _removeVariant(index),
                  ),
                ],
              ),
            );
          }),
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
        final isCreating = state is AdminProductCreating;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isCreating ? null : _submitForm,
            icon: isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Iconsax.add),
            label: Text(
              isCreating
                  ? '${state.step.replaceAll('_', ' ').toUpperCase()} (${state.current}/${state.total})'
                  : 'Create Product',
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

// ==========================================
// ADD VARIANT DIALOG
// ==========================================
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
              // Color Selection
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

              // Size Selection
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

              // SKU
              _buildDialogTextField(
                controller: _skuController,
                label: 'SKU',
                hint: 'e.g., PROD-RED-M',
              ),
              const SizedBox(height: 12),

              // Stock & Price
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
