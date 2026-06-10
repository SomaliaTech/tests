import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/category_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/category_event.dart';
import 'package:mobile/features/product/presentation/blocs/category_state.dart';

import 'package:mobile/features/product/presentation/widgets/loading/loading_product_card.dart';
import 'package:mobile/features/product/presentation/widgets/loading/loading_subcategories.dart';

import 'package:toastification/toastification.dart';
import '../blocs/product_bloc.dart';
import '../blocs/product_event.dart';
import '../blocs/product_state.dart';
import '../widgets/shared/product_card.dart';

class CategoryView extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryView({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  String _selectedSubCategoryId = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<CategoryBloc>().add(
      GetCategorySubcategoriesEvent(widget.categoryId),
    );
    context.read<ProductBloc>().add(
      GetProductsByCategoryEvent(widget.categoryId),
    );
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    if (query.isNotEmpty) {
      context.read<ProductBloc>().add(SearchProductsEvent(query));
    } else {
      final targetId = _selectedSubCategoryId == 'all'
          ? widget.categoryId
          : _selectedSubCategoryId;
      context.read<ProductBloc>().add(GetProductsByCategoryEvent(targetId));
    }
  }

  void _onSubCategorySelected(String subCategoryId) {
    setState(() {
      _selectedSubCategoryId = subCategoryId;
      _searchQuery = '';
      _searchController.clear();
    });

    final targetId = subCategoryId == 'all' ? widget.categoryId : subCategoryId;
    context.read<ProductBloc>().add(GetProductsByCategoryEvent(targetId));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSubCategories(),
          Expanded(child: _buildProductsGrid()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.categoryName,
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
    return BlocBuilder<CategoryBloc, CategoryState>(
      buildWhen: (previous, current) =>
          current is CategorySubcategoriesLoading ||
          current is CategorySubcategoriesLoaded ||
          current is CategoryError,
      builder: (context, state) {
        if (state is CategorySubcategoriesLoading) {
          return const LoadingSubcategories();
        }

        if (state is CategorySubcategoriesLoaded) {
          final subCategories = state.subcategories;

          return Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: subCategories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedSubCategoryId == 'all';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _onSubCategorySelected('all');
                        }
                      },
                      selectedColor: const Color(0xFF2ED573),
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      backgroundColor: Colors.grey[100],
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF2ED573)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  );
                }

                final subCategory = subCategories[index - 1];
                final isSelected = _selectedSubCategoryId == subCategory.id;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(subCategory.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _onSubCategorySelected(subCategory.id);
                      }
                    },
                    selectedColor: const Color(0xFF2ED573),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey[100],
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF2ED573)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProductsGrid() {
    return BlocConsumer<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductError) {
          toastification.show(
            title: const Text('Error'),
            description: Text(state.message),
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      },
      builder: (context, state) {
        if (state is ProductsLoaded) {
          final products = state.products;

          var filteredProducts = products;
          if (_searchQuery.isNotEmpty) {
            filteredProducts = products.where((product) {
              final nameMatch = product.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
              final descMatch = product.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
              final brandMatch =
                  product.brand?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false;
              return nameMatch || descMatch || brandMatch;
            }).toList();
          }

          if (filteredProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty
                        ? Icons.search_off
                        : Icons.category_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No products found for "${_searchQuery}"'
                        : 'No products in this category',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (_searchQuery.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ED573),
                      ),
                      child: const Text('Clear Search'),
                    ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 15,
              mainAxisExtent: 250,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              return ProductCard(product: filteredProducts[index]);
            },
          );
        } else if (state is ProductLoading) {
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 15,
              mainAxisExtent: 250,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return const LoadingProductCard();
            },
          );
        } else if (state is ProductError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ED573),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 15,
            mainAxisExtent: 250,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return const LoadingProductCard();
          },
        );
      },
    );
  }
}
