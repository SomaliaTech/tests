// lib/features/admin/presentation/screens/admin_products_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/permission_service.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_state.dart';
import 'package:mobile/features/admin/presentation/screens/add_product_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_product_details_screen.dart';
import 'package:mobile/features/admin/presentation/screens/edit_product_screen.dart';
import 'package:toastification/toastification.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGridView = false;
  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canDelete = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ✅ FIX: Cache last loaded products to prevent disappearing on state change
  List<AdminProductEntity> _lastLoadedProducts = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadPermissions();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    context.read<AdminProductBloc>().add(FetchAllAdminProductsEvent());
  }

  Future<void> _loadPermissions() async {
    try {
      final permissionService = GetIt.instance<PermissionService>();
      final permissions = await permissionService.loadPermissions();
      if (!mounted) return;
      setState(() {
        _canCreate = _hasPermission(permissions, 'product:create');
        _canUpdate = _hasPermission(permissions, 'product:update');
        _canDelete = _hasPermission(permissions, 'product:delete');
      });
      debugPrint('🔐 [AdminProducts] canCreate: $_canCreate');
      debugPrint('🔐 [AdminProducts] canUpdate: $_canUpdate');
      debugPrint('🔐 [AdminProducts] canDelete: $_canDelete');
    } catch (e) {
      debugPrint('❌ [AdminProducts] Failed to load permissions: $e');
      if (!mounted) return;
      setState(() {
        _canCreate = false;
        _canUpdate = false;
        _canDelete = false;
      });
    }
  }

  bool _hasPermission(List<String> permissions, String requiredPermission) {
    if (permissions.contains('*')) return true;
    if (permissions.contains(requiredPermission)) return true;
    final module = requiredPermission.split(':').first;
    return permissions.contains('$module:manage');
  }

  List<AdminProductEntity> _filterProducts(List<AdminProductEntity> products) {
    if (_searchQuery.isEmpty) return products;
    return products.where((product) {
      final searchLower = _searchQuery.toLowerCase();
      return product.name.toLowerCase().contains(searchLower) ||
          (product.brand?.toLowerCase().contains(searchLower) ?? false) ||
          (product.categoryName?.toLowerCase().contains(searchLower) ?? false);
    }).toList();
  }

  void _showToast(String message, bool isSuccess) {
    toastification.show(
      context: context,
      title: Text(message),
      type: isSuccess ? ToastificationType.success : ToastificationType.error,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  Future<void> _refreshProducts() async {
    debugPrint('🔄 [AdminProducts] Refreshing products...');
    context.read<AdminProductBloc>().add(FetchAllAdminProductsEvent());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ✅ FIX: Silent refresh — doesn't emit loading state, keeps products visible
  void _silentRefreshProducts() {
    debugPrint('🔄 [AdminProducts] Silent refresh (no loading state)...');
    context.read<AdminProductBloc>().add(SilentFetchAllAdminProductsEvent());
  }

  Future<void> _navigateToEdit(String productId) async {
    debugPrint('📝 [AdminProducts] Navigating to edit screen for: $productId');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(productId: productId),
      ),
    );
    debugPrint('↩️ [AdminProducts] Returned from edit with result: $result');
    if (result == true && mounted) {
      debugPrint(
        '🔄 [AdminProducts] Product updated, silent refreshing list...',
      );
      // ✅ FIX: Use silent refresh — no loading flash, products stay visible
      _silentRefreshProducts();
    } else {
      debugPrint('⚠️ [AdminProducts] Edit was cancelled or failed');
    }
  }

  Future<void> _navigateToAdd() async {
    debugPrint('📝 [AdminProducts] Navigating to add product screen');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    debugPrint('↩️ [AdminProducts] Returned from add with result: $result');
    if (result == true && mounted) {
      debugPrint('🔄 [AdminProducts] Product added, silent refreshing list...');
      // ✅ FIX: Use silent refresh
      _silentRefreshProducts();
    } else {
      debugPrint('⚠️ [AdminProducts] Add was cancelled or failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: BlocConsumer<AdminProductBloc, AdminProductState>(
          listener: (context, state) {
            if (state is AdminProductOperationSuccess) {
              _showToast(state.message, true);
              // ✅ FIX: Don't call _refreshProducts() here (it emits loading state).
              // The screen that triggered the operation already handles refresh
              // via Navigator.pop(context, true) → _silentRefreshProducts().
              // Only refresh here if we're on the list screen and a delete happened
              // from THIS screen (not from a sub-screen).
              if (state.message.contains('deleted')) {
                _silentRefreshProducts();
              }
            } else if (state is AdminProductsError) {
              // ✅ Only show error toast if we have no cached products
              if (_lastLoadedProducts.isEmpty) {
                _showToast(state.message, false);
              }
            }
          },
          builder: (context, state) {
            // ✅ FIX: Cache loaded products so they persist across state changes
            if (state is AdminProductsLoaded) {
              _lastLoadedProducts = state.products;
            }

            // ✅ FIX: Use cached products as fallback during loading/operation states
            final products = state is AdminProductsLoaded
                ? state.products
                : _lastLoadedProducts;

            // ✅ Only show loading spinner on FIRST load (no cache yet)
            if (state is AdminProductsLoading && _lastLoadedProducts.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refreshProducts,
                color: const Color(0xFF2ED573),
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(child: _buildSearchBar()),
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF2ED573)),
                            SizedBox(height: 16),
                            Text(
                              'Loading products...',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // ✅ Only show error state if we have no cached products
            if (state is AdminProductsError && _lastLoadedProducts.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refreshProducts,
                color: const Color(0xFF2ED573),
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(child: _buildSearchBar()),
                    SliverFillRemaining(child: _buildErrorState(state.message)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshProducts,
              color: const Color(0xFF2ED573),
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildStatsBar(products)),
                  _buildProductsList(products, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      expandedHeight: 120,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2ED573).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Iconsax.shop, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Products',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage your inventory',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        background: Container(color: Colors.white),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isGridView ? Iconsax.row_vertical : Iconsax.grid_2,
                key: ValueKey<bool>(_isGridView),
                color: const Color(0xFF6B7280),
                size: 22,
              ),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isGridView = !_isGridView);
            },
          ),
        ),
        if (_canCreate)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _navigateToAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2ED573).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.add, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(
              Iconsax.search_normal,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                style: const TextStyle(color: Color(0xFF1F2937)),
                decoration: const InputDecoration(
                  hintText: 'Search by name, brand, or category...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    Iconsax.close_circle,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ FIX: Accept products list directly instead of extracting from state
  Widget _buildStatsBar(List<AdminProductEntity> products) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }
    final filteredProducts = _filterProducts(products);
    final activeCount = products.where((p) => p.isActive).length;
    final lowStockCount = products
        .where((p) => p.stock > 0 && p.stock <= 5)
        .length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatChip(
            icon: Iconsax.box_1,
            label: 'Total',
            count: products.length,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            icon: Iconsax.tick_circle,
            label: 'Active',
            count: activeCount,
            color: const Color(0xFF2ED573),
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            icon: Iconsax.warning_2,
            label: 'Low Stock',
            count: lowStockCount,
            color: Colors.orange,
          ),
          const Spacer(),
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2ED573).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${filteredProducts.length} results',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2ED573),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIX: Accept products list directly; only show loading/error if no cache
  Widget _buildProductsList(
    List<AdminProductEntity> products,
    AdminProductState state,
  ) {
    if (products.isEmpty) {
      // If we're actively loading and have no cache, show loading
      if (state is AdminProductsLoading) {
        return const SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF2ED573)),
                SizedBox(height: 16),
                Text(
                  'Loading products...',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        );
      }
      // If error with no cache, show error
      if (state is AdminProductsError) {
        return SliverFillRemaining(child: _buildErrorState(state.message));
      }
      // Otherwise show empty state (search or truly empty)
      return SliverFillRemaining(
        child: _buildEmptyState(_searchQuery.isNotEmpty),
      );
    }

    final filteredProducts = _filterProducts(products);
    if (filteredProducts.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(_searchQuery.isNotEmpty),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      sliver: _isGridView
          ? _buildGridView(filteredProducts)
          : _buildListView(filteredProducts),
    );
  }

  Widget _buildListView(List<AdminProductEntity> products) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildProductCard(products[index]),
        );
      }, childCount: products.length),
    );
  }

  Widget _buildGridView(List<AdminProductEntity> products) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        return _buildProductGridCard(products[index]);
      }, childCount: products.length),
    );
  }

  Widget _buildProductCard(AdminProductEntity product) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminProductDetailsScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 110,
              height: 130,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: product.images.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            product.images.first.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          ),
                          if (product.compareAtPrice != null &&
                              product.compareAtPrice! > product.price)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF4757),
                                      Color(0xFFFF6B81),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF4757,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '-${((1 - product.price / product.compareAtPrice!) * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : _buildImagePlaceholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.brand != null && product.brand!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.brand!.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2ED573),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.categoryName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              product.categoryName!,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF2ED573),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (product.compareAtPrice != null &&
                                product.compareAtPrice! > product.price) ...[
                              const SizedBox(width: 6),
                              Text(
                                '\$${product.compareAtPrice!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildStatusBadge(product),
                            const SizedBox(width: 6),
                            _buildStockBadge(product),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_canUpdate || _canDelete)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_canUpdate)
                      _buildIconButton(
                        icon: Iconsax.edit_2,
                        color: Colors.blue,
                        onTap: () => _navigateToEdit(product.id),
                      ),
                    if (_canUpdate && _canDelete) const SizedBox(height: 8),
                    if (_canDelete)
                      _buildIconButton(
                        icon: Iconsax.trash,
                        color: Colors.red,
                        onTap: () => _showDeleteConfirmation(product),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGridCard(AdminProductEntity product) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminProductDetailsScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    product.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.network(
                              product.images.first.url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _buildImagePlaceholder(),
                            ),
                          )
                        : _buildImagePlaceholder(),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildStatusBadge(product),
                    ),
                    if (_canUpdate || _canDelete)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Column(
                          children: [
                            if (_canUpdate)
                              _buildSmallIconButton(
                                icon: Iconsax.edit_2,
                                color: Colors.blue,
                                onTap: () => _navigateToEdit(product.id),
                              ),
                            if (_canUpdate && _canDelete)
                              const SizedBox(height: 6),
                            if (_canDelete)
                              _buildSmallIconButton(
                                icon: Iconsax.trash,
                                color: Colors.red,
                                onTap: () => _showDeleteConfirmation(product),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF2ED573),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _buildStockBadge(product),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AdminProductEntity product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: product.isActive
            ? const Color(0xFF2ED573).withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: product.isActive
              ? const Color(0xFF2ED573).withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: product.isActive ? const Color(0xFF2ED573) : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            product.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: product.isActive ? const Color(0xFF2ED573) : Colors.red,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(AdminProductEntity product) {
    final isLowStock = product.stock > 0 && product.stock <= 5;
    final isOutOfStock = product.stock == 0;
    Color color;
    if (isOutOfStock) {
      color = Colors.red;
    } else if (isLowStock) {
      color = Colors.orange;
    } else {
      color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isOutOfStock
            ? 'Out of Stock'
            : isLowStock
            ? 'Low: ${product.stock}'
            : 'Stock: ${product.stock}',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.image, size: 36, color: Colors.grey[300]),
            const SizedBox(height: 4),
            Text(
              'No Image',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _buildSmallIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearch) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2ED573).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearch ? Iconsax.search_status : Iconsax.box_1,
                size: 64,
                color: const Color(0xFF2ED573),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearch ? 'No products found' : 'No products yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Try a different search term'
                  : 'Add your first product to get started',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            if (!isSearch && _canCreate) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToAdd,
                icon: const Icon(Iconsax.add),
                label: const Text('Add Product'),
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

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshProducts,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ED573),
                foregroundColor: Colors.white,
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

  void _showDeleteConfirmation(AdminProductEntity product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.trash, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Product',
                style: TextStyle(
                  color: Color(0xFF1F2937),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              HapticFeedback.mediumImpact();
              context.read<AdminProductBloc>().add(
                DeleteAdminProductEvent(product.id),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
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
