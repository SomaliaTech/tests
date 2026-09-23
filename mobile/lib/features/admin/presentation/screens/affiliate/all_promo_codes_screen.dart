import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/admin/domain/entities/promo_code_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_event.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_state.dart';
import 'package:mobile/features/admin/presentation/screens/affiliate/admin_promo_code_details_screen.dart';

class AdminAllPromoCodesScreen extends StatefulWidget {
  const AdminAllPromoCodesScreen({super.key});
  @override
  State<AdminAllPromoCodesScreen> createState() => _AllPromoCodesScreenState();
}

class _AllPromoCodesScreenState extends State<AdminAllPromoCodesScreen>
    with SingleTickerProviderStateMixin {
  String _filterType = 'all';
  String _filterStatus = 'all';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  List<PromoCodeEntity> _cachedPromos = [];
  bool _hasLoadedOnce = false;

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _fetchData() {
    final type = _filterType == 'all'
        ? null
        : _filterType == 'system'
        ? 'system'
        : 'affiliate';
    final isActive = _filterStatus == 'all' ? null : _filterStatus == 'active';

    context.read<AffiliateBloc>().add(
      FetchAllPromoCodesEvent(type: type, isActive: isActive),
    );
  }

  List<PromoCodeEntity> _applySearch(List<PromoCodeEntity> source) {
    if (_searchQuery.isEmpty) return source;
    return source
        .where((p) => p.code?.toLowerCase().contains(_searchQuery) ?? false)
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildAppBar(),
      ),
      body: Stack(
        children: [
          _SoftBackground(controller: _bgController),
          SafeArea(
            child: BlocConsumer<AffiliateBloc, AffiliateState>(
              listenWhen: (prev, curr) =>
                  curr is AffiliateOperationSuccess || curr is AffiliateError,
              listener: (context, state) {
                if (!mounted) return;
                if (state is AffiliateOperationSuccess) {
                  _showSnack(state.message, isError: false);
                } else if (state is AffiliateError) {
                  _showSnack(state.message, isError: true);
                }
              },
              builder: (context, state) {
                if (state is PromoCodesLoaded) {
                  _cachedPromos = state.promoCodes;
                  _hasLoadedOnce = true;
                }

                if (!_hasLoadedOnce &&
                    state is AffiliateLoading &&
                    _cachedPromos.isEmpty) {
                  return _buildSkeleton();
                }

                if (state is AffiliateError && _cachedPromos.isEmpty) {
                  return _buildErrorState(state.message);
                }

                final promos = _applySearch(_cachedPromos);

                return Column(
                  children: [
                    _buildSummaryCard(promos),
                    _buildFilters(),
                    Expanded(
                      child: promos.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () async => _fetchData(),
                              color: const Color(0xFF111827),
                              backgroundColor: Colors.white,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  40,
                                ),
                                itemCount: promos.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) =>
                                    _buildPromoCard(promos[index]),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR — White with soft shadow
  // ============================================================
  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _iconBtn(
                  icon: Iconsax.arrow_left_2,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _isSearching
                      ? TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          cursorColor: const Color(0xFF111827),
                          decoration: InputDecoration(
                            hintText: 'Search codes...',
                            hintStyle: TextStyle(
                              color: Colors.black.withValues(alpha: 0.35),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val.toLowerCase()),
                        )
                      : const Text(
                          'Promo Codes',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                ),
                const SizedBox(width: 4),
                _iconBtn(
                  icon: _isSearching
                      ? Iconsax.close_circle
                      : Iconsax.search_normal,
                  onTap: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        _searchQuery = '';
                      }
                    });
                  },
                ),
                const SizedBox(width: 4),
                _iconBtn(
                  icon: Iconsax.add,
                  filled: true,
                  onTap: _showCreateSheet,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled
                ? const Color(0xFF111827)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Icon(
          icon,
          color: filled ? Colors.white : const Color(0xFF111827),
          size: 18,
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD — soft neutral
  // ============================================================
  Widget _buildSummaryCard(List<PromoCodeEntity> promos) {
    final total = promos.length;
    final active = promos.where((p) => p.isActive == true).length;
    final system = promos.where((p) => p.affiliateId == null).length;
    final affiliate = total - system;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _summaryStat('Total', total.toString()),
            _divider(),
            _summaryStat('Active', active.toString()),
            _divider(),
            _summaryStat('System', system.toString()),
            _divider(),
            _summaryStat('Affiliate', affiliate.toString()),
          ],
        ),
      ),
    );
  }

  Widget _summaryStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.black.withValues(alpha: 0.06),
    );
  }

  // ============================================================
  // FILTERS — neutral segmented chips
  // ============================================================
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterLabel('Type'),
          const SizedBox(height: 8),
          _scrollRow([
            _filterChip(
              label: 'All',
              icon: Iconsax.element_4,
              selected: _filterType == 'all',
              onTap: () {
                setState(() => _filterType = 'all');
                _fetchData();
              },
            ),
            _filterChip(
              label: 'System',
              icon: Iconsax.global,
              selected: _filterType == 'system',
              onTap: () {
                setState(() => _filterType = 'system');
                _fetchData();
              },
            ),
            _filterChip(
              label: 'Affiliate',
              icon: Iconsax.people,
              selected: _filterType == 'affiliate',
              onTap: () {
                setState(() => _filterType = 'affiliate');
                _fetchData();
              },
            ),
          ]),
          const SizedBox(height: 12),
          _filterLabel('Status'),
          const SizedBox(height: 8),
          _scrollRow([
            _filterChip(
              label: 'All',
              icon: Iconsax.element_4,
              selected: _filterStatus == 'all',
              onTap: () {
                setState(() => _filterStatus = 'all');
                _fetchData();
              },
            ),
            _filterChip(
              label: 'Active',
              icon: Iconsax.tick_circle,
              selected: _filterStatus == 'active',
              onTap: () {
                setState(() => _filterStatus = 'active');
                _fetchData();
              },
            ),
            _filterChip(
              label: 'Inactive',
              icon: Iconsax.close_circle,
              selected: _filterStatus == 'inactive',
              onTap: () {
                setState(() => _filterStatus = 'inactive');
                _fetchData();
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _filterLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.black.withValues(alpha: 0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _scrollRow(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: children.expand((w) => [w, const SizedBox(width: 8)]).toList()
          ..removeLast(),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? const Color(0xFF111827)
                : Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected
                  ? Colors.white
                  : Colors.black.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.black.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROMO CARD — white card with subtle accents
  // ============================================================
  Widget _buildPromoCard(PromoCodeEntity promo) {
    final isSystem = promo.affiliateId == null;
    final isActive = promo.isActive ?? false;
    final isPending = !isActive;

    return GestureDetector(
      onTap: () =>
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminPromoCodeDetailsScreen(promoCode: promo),
            ),
          ).then((_) {
            if (mounted) _fetchData();
          }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isPending
                ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.05),
            width: isPending ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSystem
                        ? const Color(0xFF111827)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSystem
                          ? const Color(0xFF111827)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Icon(
                    isSystem ? Iconsax.global : Iconsax.people,
                    color: isSystem ? Colors.white : const Color(0xFF111827),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.code ?? 'UNKNOWN',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSystem ? 'System-wide code' : 'Affiliate code',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF34D399).withValues(alpha: 0.3)
                              : const Color(0xFFEF4444).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'PENDING',
                          style: TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Discount info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: const Icon(
                      Iconsax.discount_shape,
                      color: Color(0xFF111827),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo.discountType == 'PERCENTAGE'
                              ? '${promo.discountValue}% off'
                              : '\$${(promo.discountValue ?? 0).toStringAsFixed(2)} off',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Used ${promo.usedCount ?? 0}${promo.maxUses != null ? ' / ${promo.maxUses}' : ' times'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Extra info
            if (promo.affiliateName != null ||
                (promo.totalRevenue != null && promo.totalRevenue! > 0)) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (promo.affiliateName != null) ...[
                    Icon(
                      Iconsax.user,
                      size: 12,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        promo.affiliateName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (promo.totalRevenue != null &&
                      promo.totalRevenue! > 0) ...[
                    const Icon(
                      Iconsax.dollar_circle,
                      size: 12,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\$${promo.totalRevenue!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: promo.code ?? ''));
                      _showSnack('Code copied!', isError: false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.copy,
                            size: 13,
                            color: Color(0xFF4B5563),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Copy',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AdminPromoCodeDetailsScreen(promoCode: promo),
                          ),
                        ).then((_) {
                          if (mounted) _fetchData();
                        }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: -3,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.edit_2, size: 13, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Manage',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SKELETON
  // ============================================================
  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 40),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _skeletonBox(height: 82, radius: 22),
        const SizedBox(height: 12),
        _skeletonBox(height: 40, radius: 100, width: 240),
        const SizedBox(height: 8),
        _skeletonBox(height: 40, radius: 100, width: 280),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _skeletonBox(height: 180, radius: 22),
          ),
        ),
      ],
    );
  }

  Widget _skeletonBox({
    required double height,
    double radius = 12,
    double? width,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 0.9),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, opacity, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: opacity * 0.05),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY / ERROR
  // ============================================================
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.discount_shape,
                  size: 40,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'No promo codes yet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a system-wide code to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showCreateSheet,
                icon: const Icon(Iconsax.add_circle, size: 16),
                label: const Text('Create Promo Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.warning_2,
                  size: 32,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Failed to load',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.55),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Iconsax.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================
  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Iconsax.warning_2 : Iconsax.tick_circle,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // CREATE SHEET — white theme
  // ============================================================
  void _showCreateSheet() {
    final codeController = TextEditingController();
    final valueController = TextEditingController();
    final minOrderController = TextEditingController();
    final maxUsesController = TextEditingController();
    String discountType = 'PERCENTAGE';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.add_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create System Code',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Platform-wide promotional code',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _lightField(
                    controller: codeController,
                    label: 'Promo Code',
                    hint: 'e.g., SAVE20',
                    icon: Iconsax.tag,
                    uppercase: true,
                  ),
                  const SizedBox(height: 16),

                  // Discount type toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _typeChip(
                          'PERCENTAGE',
                          '% Percentage',
                          discountType,
                          (v) => setSheetState(() => discountType = v),
                        ),
                        _typeChip(
                          'FIXED',
                          '\$ Fixed',
                          discountType,
                          (v) => setSheetState(() => discountType = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _lightField(
                    controller: valueController,
                    label: 'Discount Value',
                    hint: discountType == 'PERCENTAGE'
                        ? 'e.g., 20'
                        : 'e.g., 10.00',
                    icon: discountType == 'PERCENTAGE'
                        ? Iconsax.percentage_circle
                        : Iconsax.dollar_circle,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _lightField(
                          controller: minOrderController,
                          label: 'Min Order',
                          hint: 'Optional',
                          icon: Iconsax.shopping_bag,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _lightField(
                          controller: maxUsesController,
                          label: 'Max Uses',
                          hint: 'Optional',
                          icon: Iconsax.global,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (codeController.text.trim().isEmpty ||
                            valueController.text.trim().isEmpty) {
                          _showSnack(
                            'Please fill in required fields',
                            isError: true,
                          );
                          return;
                        }

                        final data = <String, dynamic>{
                          'code': codeController.text.trim().toUpperCase(),
                          'discountType': discountType,
                          'discountValue': double.parse(valueController.text),
                        };

                        if (minOrderController.text.isNotEmpty) {
                          data['minOrderAmount'] = double.parse(
                            minOrderController.text,
                          );
                        }
                        if (maxUsesController.text.isNotEmpty) {
                          data['maxUses'] = int.parse(maxUsesController.text);
                        }

                        context.read<AffiliateBloc>().add(
                          CreateSystemPromoCodeEvent(data),
                        );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Create Promo Code',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lightField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool uppercase = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: uppercase
                ? TextCapitalization.characters
                : TextCapitalization.none,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: const Color(0xFF111827),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.black.withValues(alpha: 0.3),
                fontSize: 13,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(icon, color: const Color(0xFF6B7280), size: 18),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 50,
                minHeight: 50,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _typeChip(
    String value,
    String label,
    String current,
    ValueChanged<String> onTap,
  ) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF111827) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.black.withValues(alpha: 0.5),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SOFT BACKGROUND — barely visible neutral orbs
// ============================================================
class _SoftBackground extends StatelessWidget {
  final AnimationController controller;
  const _SoftBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final v = controller.value;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F8FB), Color(0xFFF1F1F6)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -100 + (v * 60),
                right: -120 + (v * 40),
                child: _SoftOrb(
                  size: 400,
                  color: const Color(0xFFE0E0EA),
                  opacity: 0.6,
                ),
              ),
              Positioned(
                bottom: -120 + (v * 50),
                left: -100 + (v * 60),
                child: _SoftOrb(
                  size: 350,
                  color: const Color(0xFFEDEDF3),
                  opacity: 0.7,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SoftOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _SoftOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
