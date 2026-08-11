// lib/features/product/presentation/screens/category_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/common/widgets/shared/products_grid_skeleton.dart';
import 'package:mobile/features/product/domain/entities/product.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/features/product/presentation/blocs/category_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/category_event.dart';
import 'package:mobile/features/product/presentation/blocs/category_state.dart';
import 'package:mobile/features/product/presentation/widgets/loading/subcategories_skeleton.dart';
import '../blocs/product_bloc.dart';
import '../blocs/product_event.dart';
import '../blocs/product_state.dart';
import '../widgets/shared/product_card.dart';

class CategoryView extends StatefulWidget {
  final String categoryId;
  final String? categoryName;

  const CategoryView({super.key, required this.categoryId, this.categoryName});

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  String _selectedSubCategoryId = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _wasOffline = false;
  bool _isInitialLoad = true;
  bool _isSubcategoriesLoading = true;
  String? _previousCategoryId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  void _loadInitialData() {
    setState(() {
      _isInitialLoad = true;
      _isSubcategoriesLoading = true;
    });

    // Load subcategories
    context.read<CategoryBloc>().add(
      GetCategorySubcategoriesEvent(widget.categoryId),
    );
    // Load products for "all" initially
    _loadProducts(widget.categoryId);
  }

  void _loadProducts(String targetId) {
    if (_searchQuery.isNotEmpty) {
      context.read<ProductBloc>().add(
        SearchProductsEvent(query: _searchQuery, categoryId: targetId),
      );
    } else {
      context.read<ProductBloc>().add(GetProductsByCategoryEvent(targetId));
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Implement pagination if needed
    }
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);

    if (query.isEmpty) {
      _loadProducts(
        _selectedSubCategoryId == 'all'
            ? widget.categoryId
            : _selectedSubCategoryId,
      );
      return;
    }

    // Debounce search
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchQuery == query) {
        context.read<ProductBloc>().add(
          SearchProductsEvent(query: query, categoryId: widget.categoryId),
        );
      }
    });
  }

  void _onSubCategorySelected(String subCategoryId) {
    if (_selectedSubCategoryId == subCategoryId) return;

    setState(() {
      _selectedSubCategoryId = subCategoryId;
      _searchQuery = '';
      _searchController.clear();
      _isInitialLoad = true; // Show skeleton when switching subcategories
    });

    final targetId = subCategoryId == 'all' ? widget.categoryId : subCategoryId;
    _loadProducts(targetId);
  }

  void _retryLoad() {
    _loadInitialData();
  }

  @override
  void didUpdateWidget(CategoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle navigation to same view with different category
    if (widget.categoryId != oldWidget.categoryId) {
      _previousCategoryId = oldWidget.categoryId;
      setState(() {
        _selectedSubCategoryId = 'all';
        _searchQuery = '';
        _searchController.clear();
        _isInitialLoad = true;
        _isSubcategoriesLoading = true;
      });
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Consumer<ConnectivityService>(
        builder: (context, connectivity, _) {
          final isOnline = connectivity.status == ConnectionStatus.online;

          // Handle reconnection
          if (isOnline && _wasOffline) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _retryLoad();
            });
          }
          _wasOffline = !isOnline;

          return Column(
            children: [
              _buildSearchBar(),
              _buildSubCategories(),
              Expanded(child: _buildMainContent()),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.categoryName ?? 'Products', // ✅ Added '?? "Products"' fallback
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Search in ${widget.categoryName}...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2ED573), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategories() {
    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategorySubcategoriesLoaded || state is CategoryError) {
          setState(() => _isSubcategoriesLoading = false);
        }
      },
      buildWhen: (previous, current) =>
          current is CategorySubcategoriesLoading ||
          current is CategorySubcategoriesLoaded ||
          current is CategoryError,
      builder: (context, state) {
        // Show skeleton while loading
        if (state is CategorySubcategoriesLoading && _isSubcategoriesLoading) {
          return const SubcategoriesSkeleton();
        }

        if (state is CategorySubcategoriesLoaded) {
          final subCategories = state.subcategories;

          if (subCategories.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: subCategories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSubCategoryChip(
                    id: 'all',
                    name: 'All ',
                    isSelected: _selectedSubCategoryId == 'all',
                  );
                }
                final sub = subCategories[index - 1];
                return _buildSubCategoryChip(
                  id: sub.id,
                  name: sub.name,
                  isSelected: _selectedSubCategoryId == sub.id,
                );
              },
            ),
          );
        }

        if (state is CategoryError) {
          return const SizedBox.shrink();
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSubCategoryChip({
    required String id,
    required String name,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) _onSubCategorySelected(id);
        },
        selectedColor: const Color(0xFF2ED573),
        showCheckmark: false,
        backgroundColor: Colors.grey[100],
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? const Color(0xFF2ED573) : Colors.transparent,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildMainContent() {
    return BlocConsumer<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductsLoaded) {
          setState(() => _isInitialLoad = false);
        }
        if (state is ProductError) {
          setState(() => _isInitialLoad = false);
        }
      },
      buildWhen: (previous, current) {
        // Always rebuild on state change
        return true;
      },
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildProductState(state),
        );
      },
    );
  }

  Widget _buildProductState(ProductState state) {
    // Show skeleton during initial load or when switching subcategories
    if (_isInitialLoad) {
      return const ProductsGridSkeleton(
        key: ValueKey('products_skeleton'),
        itemCount: 6,
      );
    }

    // Error state
    if (state is ProductError) {
      return _buildErrorState(state.message);
    }

    // Loaded state
    if (state is ProductsLoaded) {
      final products = _getFilteredProducts(state.products);

      if (products.isEmpty) {
        return _buildEmptyState();
      }

      return _buildProductsGrid(products);
    }

    // Fallback - show skeleton
    return const ProductsGridSkeleton(
      key: ValueKey('products_fallback_skeleton'),
      itemCount: 6,
    );
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    if (_searchQuery.isEmpty) return products;

    final query = _searchQuery.toLowerCase();
    return products.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          (p.brand?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Widget _buildProductsGrid(List<Product> products) {
    return RefreshIndicator(
      onRefresh: () async {
        _retryLoad();
      },
      color: const Color(0xFF2ED573),
      child: GridView.builder(
        key: ValueKey('products_grid_${_selectedSubCategoryId}'),
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 15,
          mainAxisExtent: 250,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index]);
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final isOffline =
        message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('connection');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isOffline
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOffline ? Iconsax.wifi_square : Iconsax.warning_2,
                size: 56,
                color: isOffline ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isOffline
                  ? 'No Internet Connection'
                  : 'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (isOffline) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.info_circle,
                      size: 20,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Check your Wi-Fi or mobile data connection and try again.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _retryLoad,
                icon: const Icon(Iconsax.refresh, size: 20),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ED573),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Iconsax.arrow_left, size: 18),
              label: const Text('Go Back'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2ED573).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty
                    ? Iconsax.search_status
                    : Iconsax.category,
                size: 56,
                color: const Color(0xFF2ED573).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No products found for "$_searchQuery"'
                  : 'No products in this category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try different keywords or browse all products'
                  : 'Check back later for new products',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _onSearch('');
                },
                icon: const Icon(Iconsax.close_circle, size: 18),
                label: const Text('Clear Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ED573),
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
          ],
        ),
      ),
    );
  }
}
