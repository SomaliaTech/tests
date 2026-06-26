import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/core/utils/toast_helper.dart';
import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';
import 'package:mobile/features/admin/domain/entities/color_entity.dart';
import 'package:mobile/features/admin/domain/entities/size_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_state.dart';
import 'package:mobile/features/admin/presentation/widgets/modern_variant_card.dart';

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

  final List<AdminProductImageEntity> _existingImages = [];
  final List<File> _newImages = [];
  final List<String> _deletedImageIds = [];

  final List<AdminProductVariantEntity> _existingVariants = [];
  final List<Map<String, dynamic>> _newVariants = [];

  AdminCategoryEntity? _selectedCategory;
  AdminCategoryEntity? _selectedSubcategory;
  bool _isActive = true;
  bool _isLoadingProduct = true;

  AdminProductEntity? _productData;
  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    print(
      '🔍 [EditProduct] Initializing screen for product: ${widget.productId}',
    );
    context.read<AdminProductBloc>().add(FetchCategoriesTreeEvent());
    context.read<AdminProductBloc>().add(FetchColorsEvent());
    context.read<AdminProductBloc>().add(FetchSizesEvent());
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    print('🔍 [EditProduct] Loading product data...');
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
    print('🔍 [EditProduct] Populating fields...');
    print('   - Name: ${product.name}');
    print('   - Price: ${product.price}');
    print('   - CategoryId: ${product.categoryId}');
    print('   - CategoryName: ${product.categoryName}');

    _nameController.text = product.name;
    _descriptionController.text = product.description ?? '';
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();
    _brandController.text = product.brand ?? '';
    _tagsController.text = product.tags ?? '';
    _isActive = product.isActive;
    _existingImages.addAll(product.images);
    _existingVariants.addAll(product.variants);

    _productData = product;

    if (_categoriesLoaded) {
      _setCategoryFromProduct(product);
    }
  }

  void _setCategoryFromProduct(AdminProductEntity product) {
    if (product.categoryId == null) {
      print('⚠️ [EditProduct] Product has no categoryId');
      return;
    }

    print('🔍 [EditProduct] Looking for category: ${product.categoryId}');

    final state = context.read<AdminProductBloc>().state;
    if (state is! AdminCategoriesLoaded) {
      print('⚠️ [EditProduct] Categories not loaded yet');
      return;
    }

    final categories = state.categories;

    for (final parentCategory in categories) {
      print(
        '   🔍 Checking parent: ${parentCategory.name} (${parentCategory.id})',
      );

      if (parentCategory.id == product.categoryId) {
        print('   ✅ Found as parent category!');
        setState(() {
          _selectedCategory = parentCategory;
          _selectedSubcategory = null;
        });
        return;
      }

      for (final child in parentCategory.children) {
        print('      🔍 Checking child: ${child.name} (${child.id})');
        if (child.id == product.categoryId) {
          print('      ✅ Found as subcategory!');
          setState(() {
            _selectedCategory = parentCategory;
            _selectedSubcategory = child;
          });
          return;
        }
      }
    }

    print('❌ [EditProduct] Category not found in tree!');
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
      ToastHelper.showError(context, 'Failed to pick images: $e');
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
    print('🔍 [EditProduct] Submitting form...');
    print('   - Selected Category: ${_selectedCategory?.name}');
    print('   - Selected Subcategory: ${_selectedSubcategory?.name}');

    if (!_formKey.currentState!.validate()) {
      print('❌ [EditProduct] Form validation failed');
      return;
    }

    final categoryId = _selectedSubcategory?.id ?? _selectedCategory?.id;
    print('   - Final CategoryId: $categoryId');

    if (categoryId == null) {
      print('❌ [EditProduct] No category selected!');
      ToastHelper.showWarning(context, 'Please select a category');
      return;
    }

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

    print('📤 [EditProduct] Sending update data: $updateData');

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
            print('✅ [EditProduct] Product data loaded');
            _populateFields(state.product);
            setState(() {
              _isLoadingProduct = false;
            });
          } else if (state is AdminCategoriesLoaded && !_categoriesLoaded) {
            print('✅ [EditProduct] Categories loaded');
            setState(() {
              _categoriesLoaded = true;
            });

            if (_productData != null) {
              _setCategoryFromProduct(_productData!);
            }
          } else if (state is AdminProductOperationSuccess) {
            print('✅ [EditProduct] Update successful');
            ToastHelper.showSuccess(context, state.message);
            Navigator.pop(context);
          } else if (state is AdminProductsError) {
            print('❌ [EditProduct] Error: ${state.message}');
            ToastHelper.showError(context, state.message);
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
                  _buildSectionCard(
                    title: 'Product Images',
                    icon: Iconsax.image,
                    child: _buildImageUploadSection(),
                  ),
                  const SizedBox(height: 16),
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
                          print('🔍 [EditProduct] Building category dropdowns');
                          print(
                            '   - Selected Category: ${_selectedCategory?.name}',
                          );
                          print(
                            '   - Selected Subcategory: ${_selectedSubcategory?.name}',
                          );

                          return Column(
                            children: [
                              _buildCategoryDropdown(
                                label: 'Parent Category',
                                categories: state.categories,
                                selectedCategory: _selectedCategory,
                                onChanged: (category) {
                                  print(
                                    '🔄 [EditProduct] Parent category changed: ${category?.name}',
                                  );
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
                                    print(
                                      '🔄 [EditProduct] Subcategory changed: ${category?.name}',
                                    );
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
                  _buildSectionCard(
                    title:
                        'Variants (${_existingVariants.length + _newVariants.length})',
                    icon: Iconsax.box_1,
                    child: _buildVariantsSection(),
                  ),
                  const SizedBox(height: 16),
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
    return Column(
      children: [
        if (_existingVariants.isEmpty && _newVariants.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(Iconsax.box_add, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No variants added yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add color and size combinations',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          )
        else ...[
          ...List.generate(_existingVariants.length, (index) {
            final variant = _existingVariants[index];
            return ModernVariantCard(
              variant: variant,
              onDelete: () => _removeExistingVariant(index),
            );
          }),
          ...List.generate(_newVariants.length, (index) {
            final variantData = _newVariants[index];
            final variant = AdminProductVariantEntity(
              id: 'temp-${DateTime.now().millisecondsSinceEpoch}-$index',
              colorName: variantData['colorName'],
              colorCode: variantData['colorCode'],
              sizeValue: variantData['sizeValue'],
              sku: variantData['sku'],
              stock: variantData['stock'],
              price: variantData['price']?.toDouble(),
            );
            return ModernVariantCard(
              variant: variant,
              isNew: true,
              onDelete: () => _removeNewVariant(index),
            );
          }),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showAddVariantDialog,
            icon: const Icon(Iconsax.add_circle, size: 20),
            label: const Text(
              'Add New Variant',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
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
  void initState() {
    super.initState();
    context.read<AdminProductBloc>().add(FetchColorsEvent());
    context.read<AdminProductBloc>().add(FetchSizesEvent());
  }

  @override
  void dispose() {
    _skuController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedColor == null) {
      ToastHelper.showWarning(context, 'Please select a color');
      return;
    }

    if (_selectedSize == null) {
      ToastHelper.showWarning(context, 'Please select a size');
      return;
    }

    final variant = {
      'colorId': _selectedColor!.id,
      'colorName': _selectedColor!.name,
      'colorCode': _selectedColor!.code,
      'sizeId': _selectedSize!.id,
      'sizeValue': _selectedSize!.value,
      'sku': _skuController.text.trim(),
      'stock': int.parse(_stockController.text),
      'price': double.parse(_priceController.text),
    };

    print('✅ [AddVariantDialog] Variant created: $variant');
    widget.onAdd(variant);
    Navigator.pop(context);
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
                      child: const Icon(
                        Iconsax.box_add,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Variant',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Create a new color/size combination',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionLabel('Color', Iconsax.colorfilter),
                const SizedBox(height: 8),
                BlocBuilder<AdminProductBloc, AdminProductState>(
                  buildWhen: (prev, current) =>
                      current is AdminColorsLoading ||
                      current is AdminColorsLoaded,
                  builder: (context, state) {
                    if (state is AdminColorsLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (state is AdminColorsLoaded) {
                      return _buildColorGrid(state.colors);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 20),
                _buildSectionLabel('Size', Iconsax.ruler),
                const SizedBox(height: 8),
                BlocBuilder<AdminProductBloc, AdminProductState>(
                  buildWhen: (prev, current) =>
                      current is AdminSizesLoading ||
                      current is AdminSizesLoaded,
                  builder: (context, state) {
                    if (state is AdminSizesLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (state is AdminSizesLoaded) {
                      return _buildSizeGrid(state.sizes);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 20),
                _buildSectionLabel('SKU', Iconsax.barcode),
                const SizedBox(height: 8),
                _buildDialogTextField(
                  controller: _skuController,
                  hint: 'e.g., PROD-BLUE-M',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Stock', Iconsax.box_1),
                          const SizedBox(height: 8),
                          _buildDialogTextField(
                            controller: _stockController,
                            hint: '0',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (int.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Price', Iconsax.money_tick),
                          const SizedBox(height: 8),
                          _buildDialogTextField(
                            controller: _priceController,
                            hint: '0.00',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
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
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Add Variant',
                          style: TextStyle(
                            fontSize: 15,
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

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildColorGrid(List<ColorEntity> colors) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        final isSelected = _selectedColor?.id == color.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hexToColor(color.code),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey.withOpacity(0.2),
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                color.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSizeGrid(List<SizeEntity> sizes) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: sizes.map((size) {
        final isSelected = _selectedSize?.id == size.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedSize = size),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              size.value.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
