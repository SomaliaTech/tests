import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ✅ Cache categories locally
  List<AdminCategoryEntity> _cachedCategories = [];
  bool _categoriesLoaded = false;
  bool _categorySet = false;

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
    print('   - Product categoryId: ${product.categoryId}');
    print('   - Product categoryName: ${product.categoryName}');

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

    // ✅ Try to set category if categories are already loaded
    if (_categoriesLoaded && !_categorySet) {
      print('   ✅ Categories already loaded, setting category now');
      _setCategoryFromProduct(product);
    } else {
      print('   ⏳ Categories not loaded yet, will set later');
    }
  }

  void _setCategoryFromProduct(AdminProductEntity product) {
    if (product.categoryId == null) {
      print('⚠️ [EditProduct] Product has no categoryId');
      return;
    }

    print('🔍 [EditProduct] Looking for category ID: ${product.categoryId}');
    print('   📂 Cached categories count: ${_cachedCategories.length}');

    // ✅ Use cached categories instead of checking BLoC state
    if (_cachedCategories.isEmpty) {
      print('⚠️ [EditProduct] No cached categories available');
      return;
    }

    for (final parentCategory in _cachedCategories) {
      print(
        '   🔍 Checking parent: ${parentCategory.name} (${parentCategory.id})',
      );

      if (parentCategory.id == product.categoryId) {
        print('   ✅ Found as parent category!');
        setState(() {
          _selectedCategory = parentCategory;
          _selectedSubcategory = null;
          _categorySet = true;
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
            _categorySet = true;
          });
          return;
        }
      }
    }

    print('❌ [EditProduct] Category not found in cached categories!');
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
    setState(() => _newImages.removeAt(index));
  }

  void _showAddVariantDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddVariantDialog(
        existingVariants: [
          ..._existingVariants.map(
            (v) => {'colorId': v.colorId, 'sizeId': v.sizeId},
          ),
          ..._newVariants,
        ],
        onAdd: (newVariants) {
          setState(() {
            _newVariants.addAll(newVariants);
          });
        },
      ),
    );
  }

  void _removeExistingVariant(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _existingVariants.removeAt(index));
  }

  void _removeNewVariant(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _newVariants.removeAt(index));
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      ToastHelper.showError(context, 'Please fill all required fields');
      return;
    }

    if (_selectedCategory == null) {
      ToastHelper.showWarning(context, 'Please select a category');
      return;
    }

    HapticFeedback.mediumImpact();
    final categoryId = _selectedSubcategory?.id ?? _selectedCategory!.id;

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
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocConsumer<AdminProductBloc, AdminProductState>(
        listener: (context, state) {
          // ✅ Handle categories loaded - CACHE them
          if (state is AdminCategoriesLoaded) {
            print(
              '✅ [EditProduct] Categories loaded - caching ${state.categories.length} categories',
            );
            _cachedCategories = state.categories;
            setState(() => _categoriesLoaded = true);

            // ✅ If product data is already loaded but category not set yet, set it now
            if (_productData != null && !_categorySet) {
              print('   🔄 Product already loaded, setting category now');
              _setCategoryFromProduct(_productData!);
            }
          }
          // ✅ Handle product data loaded
          else if (state is AdminProductDetailsLoaded && _isLoadingProduct) {
            print('✅ [EditProduct] Product data loaded');
            _populateFields(state.product);
            setState(() => _isLoadingProduct = false);
          } else if (state is AdminProductOperationSuccess) {
            HapticFeedback.mediumImpact();
            ToastHelper.showSuccess(context, state.message);
            Navigator.pop(context);
          } else if (state is AdminProductsError) {
            HapticFeedback.heavyImpact();
            ToastHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final isUpdating = state is AdminProductCreating;

          if (_isLoadingProduct) {
            return const Scaffold(
              backgroundColor: Color(0xFFF8F9FA),
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            );
          }

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildHeader(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionCard(
                              title: 'Product Images',
                              subtitle:
                                  '${_existingImages.length + _newImages.length} images',
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
                                          label: 'Base Price',
                                          hint: '0.00',
                                          icon: Iconsax.money_tick,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Price is required';
                                            }
                                            if (double.tryParse(value) ==
                                                null) {
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
                                          label: 'Base Stock',
                                          hint: '0',
                                          icon: Iconsax.box,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
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
                              subtitle: _selectedCategory != null
                                  ? 'Selected: ${_selectedSubcategory?.name ?? _selectedCategory!.name}'
                                  : (_categoriesLoaded
                                        ? 'Select a category'
                                        : 'Loading categories...'),
                              icon: Iconsax.category,
                              child: _categoriesLoaded
                                  ? _buildCategoryDropdowns()
                                  : const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: CircularProgressIndicator(
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            _buildSectionCard(
                              title: 'Variants',
                              subtitle:
                                  '${_existingVariants.length + _newVariants.length} variant${(_existingVariants.length + _newVariants.length) == 1 ? '' : 's'}',
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
                                    onChanged: (value) =>
                                        setState(() => _isActive = value),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSubmitButton(isUpdating: isUpdating),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isUpdating)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Updating Product...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Saving changes and uploading',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryDropdowns() {
    if (_cachedCategories.isEmpty) {
      return _buildWarningBox('No categories available.');
    }

    return Column(
      children: [
        _buildCategoryDropdown(
          label: 'Parent Category',
          categories: _cachedCategories,
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

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Iconsax.arrow_left_2,
              color: Color(0xFF1F2937),
              size: 20,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            children: [
              Icon(Iconsax.edit, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Update product details',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2ED573), Color(0xFF1ABC9C), Color(0xFF16A085)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                right: 60,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBox(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
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
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.camera,
                        size: 32,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to upload images',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PNG, JPG up to 5MB',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
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
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
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
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(image.url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => _removeExistingImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Iconsax.close_circle,
                            color: Color(0xFFFF4757),
                            size: 18,
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
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_newImages[newIndex]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _removeNewImage(newIndex),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Iconsax.close_circle,
                          color: Color(0xFFFF4757),
                          size: 18,
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
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.box_add,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No variants added yet',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
            return _ModernVariantCard(
              variantData: {
                'colorName': variant.colorName ?? '',
                'colorCode': variant.colorCode ?? '#000000',
                'sizeValue': variant.sizeValue ?? '',
                'sku': variant.sku,
                'stock': variant.stock,
                'price': variant.price,
              },
              onDelete: () => _removeExistingVariant(index),
            );
          }),
          ...List.generate(_newVariants.length, (index) {
            return _ModernVariantCard(
              variantData: _newVariants[index],
              isNew: true,
              onDelete: () => _removeNewVariant(index),
            );
          }),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _showAddVariantDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 6,
              shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.add_circle, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add New Variant',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton({required bool isUpdating}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isUpdating ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isUpdating
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
                      Icon(Iconsax.tick_circle, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Update Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
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
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.15),
                      AppTheme.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                  ],
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
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AdminCategoryEntity>(
              value: selectedCategory,
              hint: const Text(
                'Select category',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
              isExpanded: true,
              icon: const Icon(Iconsax.arrow_down_2, color: Color(0xFF9CA3AF)),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category.name,
                    style: const TextStyle(color: Color(0xFF1F2937)),
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
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                value ? Iconsax.tick_circle : Iconsax.close_circle,
                color: value ? AppTheme.primaryColor : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

// Modern Variant Card (same as before)
class _ModernVariantCard extends StatelessWidget {
  final Map<String, dynamic> variantData;
  final bool isNew;
  final VoidCallback onDelete;

  const _ModernVariantCard({
    required this.variantData,
    this.isNew = false,
    required this.onDelete,
  });

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final colorName = variantData['colorName'] ?? '';
    final colorCode = variantData['colorCode'] ?? '#000000';
    final sizeValue = variantData['sizeValue'] ?? '';
    final sku = variantData['sku'] as String?;
    final stock = variantData['stock'];
    final price = variantData['price'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew
              ? const Color(0xFF2ED573).withValues(alpha: 0.3)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hexToColor(colorCode),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _hexToColor(colorCode).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            colorName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sizeValue.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (sku != null && sku.isNotEmpty)
                      Text(
                        'SKU: $sku',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4757).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.trash,
                    color: Color(0xFFFF4757),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Iconsax.box_1,
                  label: 'Stock',
                  value: stock?.toString() ?? '0',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  icon: Iconsax.money_tick,
                  label: 'Price',
                  value: price != null
                      ? '\$${(price as num).toStringAsFixed(2)}'
                      : 'Default',
                  color: const Color(0xFF2ED573),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Add Variant Dialog (same as AddProductScreen)
class _AddVariantDialog extends StatefulWidget {
  final List<Map<String, dynamic>> existingVariants;
  final void Function(List<Map<String, dynamic>>) onAdd;

  const _AddVariantDialog({
    required this.existingVariants,
    required this.onAdd,
  });

  @override
  State<_AddVariantDialog> createState() => _AddVariantDialogState();
}

class _AddVariantDialogState extends State<_AddVariantDialog> {
  final _stockController = TextEditingController(text: '0');
  final _priceController = TextEditingController();

  final Set<ColorEntity> _selectedColors = {};
  final Set<SizeEntity> _selectedSizes = {};

  bool _hasCustomPrice = false;
  bool _hasCustomStock = false;

  @override
  void initState() {
    super.initState();
    context.read<AdminProductBloc>().add(FetchColorsEvent());
    context.read<AdminProductBloc>().add(FetchSizesEvent());
  }

  @override
  void dispose() {
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedColors.isEmpty) {
      ToastHelper.showWarning(context, 'Please select at least one color');
      return;
    }
    if (_selectedSizes.isEmpty) {
      ToastHelper.showWarning(context, 'Please select at least one size');
      return;
    }

    final int? stock = _hasCustomStock && _stockController.text.isNotEmpty
        ? int.tryParse(_stockController.text)
        : null;
    final double? price = _hasCustomPrice && _priceController.text.isNotEmpty
        ? double.tryParse(_priceController.text)
        : null;

    if (_hasCustomStock && stock == null) {
      ToastHelper.showError(context, 'Invalid stock value');
      return;
    }
    if (_hasCustomPrice && price == null) {
      ToastHelper.showError(context, 'Invalid price value');
      return;
    }

    final newVariants = <Map<String, dynamic>>[];

    for (final color in _selectedColors) {
      for (final size in _selectedSizes) {
        final exists = widget.existingVariants.any(
          (v) => v['colorId'] == color.id && v['sizeId'] == size.id,
        );
        if (exists) continue;

        newVariants.add({
          'colorId': color.id,
          'colorName': color.name,
          'colorCode': color.code,
          'sizeId': size.id,
          'sizeValue': size.value,
          'sku': null,
          'stock': stock,
          'price': price,
        });
      }
    }

    if (newVariants.isEmpty) {
      ToastHelper.showWarning(context, 'All combinations already exist');
      return;
    }

    HapticFeedback.mediumImpact();
    widget.onAdd(newVariants);
    Navigator.pop(context);
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.box_add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Variants',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Select multiple colors & sizes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionLabel(
                'Colors',
                Iconsax.colorfilter,
                'Select one or more',
              ),
              const SizedBox(height: 12),
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
                    if (state.colors.isEmpty)
                      return _buildEmptyState('No colors available');
                    return _buildColorGrid(state.colors);
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 20),
              _buildSectionLabel('Sizes', Iconsax.ruler, 'Select one or more'),
              const SizedBox(height: 12),
              BlocBuilder<AdminProductBloc, AdminProductState>(
                buildWhen: (prev, current) =>
                    current is AdminSizesLoading || current is AdminSizesLoaded,
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
                    if (state.sizes.isEmpty)
                      return _buildEmptyState('No sizes available');
                    return _buildSizeGrid(state.sizes);
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),
              _buildPreview(),
              const SizedBox(height: 20),
              _buildOptionalField(
                label: 'Set Custom Stock',
                enabled: _hasCustomStock,
                onChanged: (v) => setState(() => _hasCustomStock = v),
                child: _buildDialogTextField(
                  controller: _stockController,
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionalField(
                label: 'Set Custom Price',
                enabled: _hasCustomPrice,
                onChanged: (v) => setState(() => _hasCustomPrice = v),
                child: _buildDialogTextField(
                  controller: _priceController,
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        shadowColor: AppTheme.primaryColor.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
    );
  }

  Widget _buildSectionLabel(String label, IconData icon, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorGrid(List<ColorEntity> colors) {
    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: colors.map((color) {
        final isSelected = _selectedColors.contains(color);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isSelected) {
                _selectedColors.remove(color);
              } else {
                _selectedColors.add(color);
              }
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hexToColor(color.code),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.withValues(alpha: 0.2),
                        width: isSelected ? 3 : 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 22)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                color.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFF1F2937),
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
        final isSelected = _selectedSizes.contains(size);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isSelected) {
                _selectedSizes.remove(size);
              } else {
                _selectedSizes.add(size);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              size.value.toUpperCase(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreview() {
    final count = _selectedColors.length * _selectedSizes.length;
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Iconsax.box_1, color: AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Will create $count variant${count > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Text(
            '${_selectedColors.length} × ${_selectedSizes.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalField({
    required String label,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: enabled,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        if (enabled) ...[const SizedBox(height: 8), child],
      ],
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFF1F2937)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
