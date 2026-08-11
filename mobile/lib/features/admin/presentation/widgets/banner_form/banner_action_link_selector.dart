import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_state.dart';
import 'package:mobile/features/product/data/models/banner_form_data.dart';

class BannerActionLinkSelector extends StatelessWidget {
  final BannerFormData formData;
  final VoidCallback onFormChanged;

  const BannerActionLinkSelector({
    super.key,
    required this.formData,
    required this.onFormChanged,
  });

  @override
  Widget build(BuildContext context) {
    final link = formData.actionLink ?? '';

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
          onTap: () => _showLinkSelectorSheet(context),
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
                    onTap: () {
                      formData.actionLink = null;
                      onFormChanged();
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

  void _selectLink(String link) {
    formData.actionLink = link;
    onFormChanged();
  }

  void _showLinkSelectorSheet(BuildContext context) {
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
                          _showCategoryPicker(context);
                        },
                      ),
                      _buildSheetOption(
                        Iconsax.box_1,
                        'Select Product',
                        'Link to a specific product',
                        Colors.teal,
                        () {
                          Navigator.pop(ctx);
                          _showProductPicker(context);
                        },
                      ),
                      const Divider(height: 32),

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
                      const Divider(height: 32),
                      _buildSheetOption(
                        Iconsax.link,
                        'Custom Link',
                        'Enter a custom path or URL',
                        Colors.grey,
                        () {
                          Navigator.pop(ctx);
                          _showCustomLinkDialog(context);
                        },
                      ),
                      const SizedBox(height: 20),
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

  void _showProductPicker(BuildContext context) {
    context.read<AdminProductBloc>().add(FetchAllAdminProductsEvent());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<AdminProductBloc, AdminProductState>(
                  builder: (context, state) {
                    if (state is AdminProductsLoading)
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2ED573),
                        ),
                      );
                    if (state is AdminProductsLoaded) {
                      if (state.products.isEmpty)
                        return const Center(
                          child: Text(
                            'No products found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.products.length,
                        itemBuilder: (context, index) => _buildProductListItem(
                          context,
                          state.products[index],
                        ),
                      );
                    }
                    if (state is AdminProductsError)
                      return Center(
                        child: Text(
                          'Error: ${state.message}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductListItem(BuildContext context, dynamic product) {
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

  void _showCategoryPicker(BuildContext context) {
    context.read<AdminProductBloc>().add(FetchCategoriesTreeEvent());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<AdminProductBloc, AdminProductState>(
                  builder: (context, state) {
                    if (state is AdminCategoriesLoading)
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2ED573),
                        ),
                      );
                    if (state is AdminCategoriesLoaded) {
                      if (state.categories.isEmpty)
                        return const Center(
                          child: Text(
                            'No categories found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.categories.length,
                        itemBuilder: (context, index) => _buildCategoryListItem(
                          context,
                          state.categories[index],
                        ),
                      );
                    }
                    if (state is AdminCategoriesError)
                      return Center(
                        child: Text(
                          'Error: ${state.message}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryListItem(BuildContext context, dynamic category) {
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

  void _showCustomLinkDialog(BuildContext context) {
    final controller = TextEditingController(text: formData.actionLink ?? '');
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
  // 🛡️ SAFE PROPERTY EXTRACTORS
  // ==========================================
  String? _extractImageUrl(dynamic p) {
    try {
      if (p.imageUrl != null) return p.imageUrl.toString();
    } catch (_) {}
    try {
      if (p.mainImage != null) return p.mainImage.toString();
    } catch (_) {}
    try {
      if (p.images != null && p.images.isNotEmpty) {
        final f = p.images.first;
        if (f is String) return f;
        if (f.url != null) return f.url.toString();
      }
    } catch (_) {}
    try {
      if (p.imageUrls != null && p.imageUrls.isNotEmpty)
        return p.imageUrls.first.toString();
    } catch (_) {}
    return null;
  }

  String _extractName(dynamic p) {
    try {
      return p.name ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _extractPrice(dynamic p) {
    try {
      return '\$${(p.price as num).toStringAsFixed(2)}';
    } catch (_) {
      return '\$0.00';
    }
  }

  String _extractStock(dynamic p) {
    try {
      return '${p.stock}';
    } catch (_) {
      return '0';
    }
  }

  String _extractSlugOrId(dynamic p) {
    try {
      if (p.slug != null && p.slug.toString().isNotEmpty) return p.slug;
    } catch (_) {}
    try {
      return p.id;
    } catch (_) {
      return '';
    }
  }

  String _extractCategoryName(dynamic c) {
    try {
      return c.name ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _extractCategoryDescription(dynamic c) {
    try {
      return c.description ?? '';
    } catch (_) {
      return '';
    }
  }

  String _extractCategorySlugOrId(dynamic c) {
    try {
      if (c.slug != null && c.slug.toString().isNotEmpty) return c.slug;
    } catch (_) {}
    try {
      return c.id;
    } catch (_) {
      return '';
    }
  }
}
