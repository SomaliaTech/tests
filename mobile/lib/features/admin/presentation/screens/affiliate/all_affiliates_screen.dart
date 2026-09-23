import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/admin/domain/entities/affiliate_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_event.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_state.dart';

class AdminAllAffiliatesScreen extends StatefulWidget {
  const AdminAllAffiliatesScreen({super.key});
  @override
  State<AdminAllAffiliatesScreen> createState() => _AllAffiliatesScreenState();
}

class _AllAffiliatesScreenState extends State<AdminAllAffiliatesScreen>
    with SingleTickerProviderStateMixin {
  String? _currentStatus;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Cache so the list never blanks out
  List<AffiliateEntity> _cachedAffiliates = [];
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
    context.read<AffiliateBloc>().add(
      FetchAllAffiliatesEvent(
        status: _currentStatus,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      ),
    );
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
                if (state is AffiliatesLoaded) {
                  _cachedAffiliates = state.affiliates;
                  _hasLoadedOnce = true;
                }

                if (!_hasLoadedOnce &&
                    state is AffiliateLoading &&
                    _cachedAffiliates.isEmpty) {
                  return _buildSkeleton();
                }

                if (state is AffiliateError && _cachedAffiliates.isEmpty) {
                  return _buildErrorState(state.message);
                }

                final affiliates = _cachedAffiliates;

                return Column(
                  children: [
                    _buildSummaryCard(affiliates),
                    _buildFilters(),
                    Expanded(
                      child: affiliates.isEmpty
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
                                itemCount: affiliates.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) =>
                                    _buildAffiliateCard(affiliates[index]),
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
                            hintText: 'Search name or code...',
                            hintStyle: TextStyle(
                              color: Colors.black.withValues(alpha: 0.35),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                            _fetchData();
                          },
                        )
                      : const Text(
                          'All Affiliates',
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
                        _fetchData();
                      }
                    });
                  },
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
  // SUMMARY CARD
  // ============================================================
  Widget _buildSummaryCard(List<AffiliateEntity> affiliates) {
    final total = affiliates.length;
    final active = affiliates.where((a) => a.status == 'ACTIVE').length;
    final suspended = total - active;
    final totalEarned = affiliates.fold<double>(
      0,
      (sum, a) => sum + a.totalEarnings,
    );

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
            _summaryStat('Suspended', suspended.toString()),
            _divider(),
            _summaryStat('Earned', '\$${_formatCompact(totalEarned)}'),
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
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.45),
              fontSize: 10,
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

  String _formatCompact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
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
          _filterLabel('Status'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _filterChip(
                  label: 'All',
                  icon: Iconsax.element_4,
                  selected: _currentStatus == null,
                  onTap: () {
                    setState(() => _currentStatus = null);
                    _fetchData();
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Active',
                  icon: Iconsax.tick_circle,
                  selected: _currentStatus == 'ACTIVE',
                  onTap: () {
                    setState(() => _currentStatus = 'ACTIVE');
                    _fetchData();
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Suspended',
                  icon: Iconsax.pause_circle,
                  selected: _currentStatus == 'SUSPENDED',
                  onTap: () {
                    setState(() => _currentStatus = 'SUSPENDED');
                    _fetchData();
                  },
                ),
              ],
            ),
          ),
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
  // AFFILIATE CARD
  // ============================================================
  Widget _buildAffiliateCard(AffiliateEntity aff) {
    final isActive = aff.status == 'ACTIVE';
    final isSuspended = !isActive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSuspended
              ? const Color(0xFFEF4444).withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.05),
          width: isSuspended ? 1.5 : 1,
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
          // ── Header row ──
          Row(
            children: [
              _avatar(aff),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aff.userName ?? 'Unknown Affiliate',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      aff.userPhone ?? aff.userEmail ?? 'No contact',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                  isActive ? 'ACTIVE' : 'SUSPENDED',
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
            ],
          ),

          const SizedBox(height: 14),

          // ── Promo code box ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: const Icon(
                    Iconsax.discount_shape,
                    color: Color(0xFF111827),
                    size: 15,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    aff.uniqueCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: aff.uniqueCode));
                    _showSnack('Code copied!', isError: false);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: const Icon(
                      Iconsax.copy,
                      color: Color(0xFF4B5563),
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Stats row ──
          Row(
            children: [
              _stat(
                '\$${aff.totalEarnings.toStringAsFixed(2)}',
                'Earned',
                const Color(0xFF059669),
              ),
              const SizedBox(width: 8),
              _stat(
                '\$${aff.pendingEarnings.toStringAsFixed(2)}',
                'Pending',
                const Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              _stat(
                aff.totalOrders.toString(),
                'Orders',
                const Color(0xFF111827),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Actions ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showStatusSheet(aff),
                  icon: Icon(
                    isActive ? Iconsax.close_circle : Iconsax.tick_circle,
                    size: 16,
                  ),
                  label: Text(isActive ? 'Suspend' : 'Activate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isActive
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF059669),
                    side: BorderSide(
                      color: isActive
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF059669),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRateSheet(aff),
                  icon: const Icon(Iconsax.percentage_square, size: 16),
                  label: const Text('Edit Rate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(AffiliateEntity aff) {
    final hasImage =
        aff.userProfileImage != null && aff.userProfileImage!.isNotEmpty;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(aff.userProfileImage!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasImage
          ? Center(
              child: Text(
                (aff.userName?.isNotEmpty ?? false)
                    ? aff.userName![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
            )
          : null,
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.black.withValues(alpha: 0.45),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SKELETON / EMPTY / ERROR
  // ============================================================
  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 40),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _skeletonBox(height: 82, radius: 22),
        const SizedBox(height: 12),
        _skeletonBox(height: 40, radius: 100, width: 240),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _skeletonBox(height: 220, radius: 22),
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
                  Iconsax.people,
                  size: 40,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'No affiliates found',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Affiliates will appear here once they are approved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.5),
                  height: 1.5,
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
  // STATUS SHEET
  // ============================================================
  void _showStatusSheet(AffiliateEntity aff) {
    final isActive = aff.status == 'ACTIVE';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? Iconsax.warning_2 : Iconsax.tick_circle,
                  color: isActive
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF059669),
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isActive ? 'Suspend Affiliate?' : 'Activate Affiliate?',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  isActive
                      ? '${aff.userName ?? 'This affiliate'} will no longer be able to earn commissions or use their promo codes.'
                      : '${aff.userName ?? 'This affiliate'} will be reinstated and can start earning commissions again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.55),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AffiliateBloc>().add(
                      UpdateAffiliateEvent(
                        aff.id,
                        status: isActive ? 'SUSPENDED' : 'ACTIVE',
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isActive ? 'Yes, Suspend' : 'Yes, Activate',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RATE SHEET
  // ============================================================
  void _showRateSheet(AffiliateEntity aff) {
    final controller = TextEditingController(
      text: aff.commissionRate.toString(),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.percentage_square,
                    color: Color(0xFF111827),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Update Commission Rate',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  aff.userName ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: true,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: const Color(0xFF111827),
                    decoration: const InputDecoration(
                      labelText: 'Commission Percentage',
                      labelStyle: TextStyle(color: Color(0xFF6B7280)),
                      suffixText: '%',
                      suffixStyle: TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      final rate = double.tryParse(controller.text);
                      if (rate != null && rate >= 0 && rate <= 100) {
                        context.read<AffiliateBloc>().add(
                          UpdateAffiliateEvent(aff.id, commissionRate: rate),
                        );
                        Navigator.pop(ctx);
                      }
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
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SOFT BACKGROUND
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
