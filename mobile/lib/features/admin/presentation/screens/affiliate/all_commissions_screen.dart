import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/affiliate_commission_model.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_event.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_state.dart';

class AdminAllCommissionsScreen extends StatefulWidget {
  const AdminAllCommissionsScreen({super.key});
  @override
  State<AdminAllCommissionsScreen> createState() =>
      _AllCommissionsScreenState();
}

class _AllCommissionsScreenState extends State<AdminAllCommissionsScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _selectedIds = {};
  String? _currentStatus;

  // Cached data so the list never blanks out
  List<AffiliateCommissionModel> _cachedCommissions = [];
  Map<String, dynamic> _cachedSummary = {};
  bool _hasLoadedOnce = false;

  // ✅ Payout loading overlay
  bool _isPayingOut = false;

  // ✅ Admin's own phone (business wallet — the "FROM" side)
  String? _adminPhone;

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadAdminPhone();
      if (mounted) _fetchData();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminPhone() async {
    try {
      final storage = sl<StorageService>();
      final phone = await storage.getUserPhone();
      if (mounted) setState(() => _adminPhone = phone);
    } catch (_) {}
  }

  void _fetchData() {
    context.read<AffiliateBloc>().add(
      FetchAllCommissionsEvent(status: _currentStatus),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          BlocConsumer<AffiliateBloc, AffiliateState>(
            listenWhen: (prev, curr) =>
                curr is AffiliateOperationSuccess || curr is AffiliateError,
            listener: (context, state) {
              if (!mounted) return;

              if (state is AffiliateOperationSuccess) {
                if (_isPayingOut) {
                  setState(() => _isPayingOut = false);
                }
                _showSnack(state.message, isError: false);
                setState(() => _selectedIds.clear());
                _fetchData();
              } else if (state is AffiliateError) {
                if (_isPayingOut) {
                  setState(() => _isPayingOut = false);
                }
                _showSnack(state.message, isError: true);
              }
            },
            builder: (context, state) {
              if (state is CommissionsLoaded) {
                final data = state.data;
                _cachedSummary =
                    (data['summary'] as Map<String, dynamic>?) ?? {};
                final rawItems = data['items'] as List? ?? [];
                _cachedCommissions = rawItems
                    .map((j) => AffiliateCommissionModel.fromJson(j))
                    .toList();
                _hasLoadedOnce = true;
              }

              if (!_hasLoadedOnce &&
                  _cachedCommissions.isEmpty &&
                  (state is AffiliateLoading || state is AffiliateInitial)) {
                return _buildSkeleton();
              }

              if (state is AffiliateError &&
                  _cachedCommissions.isEmpty &&
                  !_hasLoadedOnce) {
                return _buildErrorState(state.message);
              }

              return Stack(
                children: [
                  _SoftBackground(controller: _bgController),
                  Column(
                    children: [
                      _buildSummaryStrip(_cachedSummary),
                      _buildFilters(),
                      Expanded(child: _buildCommissionList()),
                      if (_selectedIds.isNotEmpty) _buildPayActionBar(),
                    ],
                  ),
                ],
              );
            },
          ),

          if (_isPayingOut) _buildPayoutOverlay(),
        ],
      ),
    );
  }

  // ============================================================
  // PAYOUT OVERLAY
  // ============================================================
  Widget _buildPayoutOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF059669),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sending Payouts…',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transferring money to ${_selectedIds.length} affiliate(s). Do not close this screen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.55),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
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
                  const Expanded(
                    child: Text(
                      'Commissions',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  if (_cachedCommissions.any((c) => c.status == 'PENDING') &&
                      !_isPayingOut)
                    TextButton.icon(
                      onPressed: _toggleSelectAll,
                      icon: Icon(
                        _selectedIds.length ==
                                _cachedCommissions
                                    .where((c) => c.status == 'PENDING')
                                    .length
                            ? Iconsax.tick_circle5
                            : Iconsax.tick_circle,
                        size: 16,
                      ),
                      label: Text(
                        _selectedIds.isEmpty ? 'Select All' : 'Clear',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                      ),
                    ),
                  _iconBtn(
                    icon: Iconsax.refresh,
                    onTap: _isPayingOut ? () {} : _fetchData,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Icon(icon, color: const Color(0xFF111827), size: 18),
      ),
    );
  }

  // ============================================================
  // SUMMARY STRIP
  // ============================================================
  Widget _buildSummaryStrip(Map<String, dynamic> summary) {
    final pending = (summary['pendingTotal'] ?? 0).toDouble();
    final paid = (summary['paidTotal'] ?? 0).toDouble();
    final cancelled = (summary['cancelledTotal'] ?? 0).toDouble();

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
            _summaryStat(
              'Pending',
              '\$${_compact(pending)}',
              const Color(0xFFD97706),
            ),
            _divider(),
            _summaryStat(
              'Paid',
              '\$${_compact(paid)}',
              const Color(0xFF059669),
            ),
            _divider(),
            _summaryStat(
              'Cancelled',
              '\$${_compact(cancelled)}',
              const Color(0xFFDC2626),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.45),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
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

  String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  // ============================================================
  // FILTER CHIPS
  // ============================================================
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'STATUS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.black.withValues(alpha: 0.4),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _chip('All', null, Iconsax.element_4),
                const SizedBox(width: 8),
                _chip('Pending', 'PENDING', Iconsax.clock),
                const SizedBox(width: 8),
                _chip('Paid', 'PAID', Iconsax.tick_circle),
                const SizedBox(width: 8),
                _chip('Cancelled', 'CANCELLED', Iconsax.close_circle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value, IconData icon) {
    final isSelected = _currentStatus == value;
    return GestureDetector(
      onTap: _isPayingOut
          ? null
          : () {
              setState(() => _currentStatus = value);
              _fetchData();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF111827)
                : Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: isSelected
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
              color: isSelected
                  ? Colors.white
                  : Colors.black.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.black.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMMISSION LIST
  // ============================================================
  Widget _buildCommissionList() {
    if (_cachedCommissions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _fetchData(),
      color: const Color(0xFF111827),
      backgroundColor: Colors.white,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        itemCount: _cachedCommissions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildCommissionCard(_cachedCommissions[index]),
      ),
    );
  }

  Widget _buildCommissionCard(AffiliateCommissionModel c) {
    final isSelected = _selectedIds.contains(c.id);
    final isPending = c.status == 'PENDING';
    final statusStyle = _statusStyle(c.status);
    final canSelect = isPending && !_isPayingOut;

    return GestureDetector(
      onTap: canSelect ? () => _toggleSelection(c.id) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF111827)
                : Colors.black.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
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
          children: [
            Row(
              children: [
                if (isPending) ...[
                  _checkbox(isSelected),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusStyle.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusStyle.border),
                  ),
                  child: Icon(
                    statusStyle.icon,
                    color: statusStyle.fg,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.affiliateName ?? 'Unknown Affiliate',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Order ${c.orderNumber ?? '—'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+\$${c.commissionAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: statusStyle.fg,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusStyle.bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusStyle.border),
                      ),
                      child: Text(
                        c.status,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: statusStyle.fg,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _miniInfo(Iconsax.percentage_circle, '${c.commissionRate}%'),
                  Container(
                    width: 1,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                  _miniInfo(
                    Iconsax.shopping_bag,
                    'Order \$${c.orderAmount.toStringAsFixed(2)}',
                  ),
                  const Spacer(),
                  Text(
                    _formatDate('${c.createdAt}'),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkbox(bool isSelected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF111827) : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? const Color(0xFF111827)
              : Colors.black.withValues(alpha: 0.2),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: isSelected
          ? const Icon(Iconsax.tick_circle, color: Colors.white, size: 14)
          : null,
    );
  }

  Widget _miniInfo(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.black.withValues(alpha: 0.4)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.black.withValues(alpha: 0.6),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAY ACTION BAR
  // ============================================================
  Widget _buildPayActionBar() {
    final selectedCommissions = _cachedCommissions
        .where((c) => _selectedIds.contains(c.id))
        .toList();
    final totalAmount = selectedCommissions.fold(
      0.0,
      (sum, c) => sum + c.commissionAmount,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedIds.length} selected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.5),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isPayingOut
                  ? null
                  : () => _showPayConfirmation(totalAmount),
              icon: const Icon(Iconsax.dollar_circle, size: 18),
              label: const Text(
                'Pay Now',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFF111827,
                ).withValues(alpha: 0.4),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
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
    );
  }

  // ============================================================
  // SKELETON / EMPTY / ERROR
  // ============================================================
  Widget _buildSkeleton() {
    return Stack(
      children: [
        _SoftBackground(controller: _bgController),
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _skeletonBox(height: 82, radius: 22),
            const SizedBox(height: 12),
            _skeletonBox(height: 40, radius: 100, width: 280),
            const SizedBox(height: 16),
            ...List.generate(
              5,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _skeletonBox(height: 130, radius: 22),
              ),
            ),
          ],
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
    return Stack(
      children: [
        _SoftBackground(controller: _bgController),
        ListView(
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
                      Iconsax.wallet_money,
                      size: 40,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'No commissions found',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStatus == null
                        ? 'Commissions will appear here once affiliates make sales.'
                        : 'No ${_currentStatus!.toLowerCase()} commissions right now.',
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
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Stack(
      children: [
        _SoftBackground(controller: _bgController),
        ListView(
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
        ),
      ],
    );
  }

  // ============================================================
  // PAY CONFIRMATION SHEET — shows BOTH phone numbers
  // ============================================================
  void _showPayConfirmation(double totalAmount) {
    // Group selected commissions by affiliate
    final selectedCommissions = _cachedCommissions
        .where((c) => _selectedIds.contains(c.id))
        .toList();

    // Map: affiliateName → { amount, phone }
    final Map<String, Map<String, dynamic>> perAffiliate = {};
    for (final c in selectedCommissions) {
      final name = c.affiliateName ?? 'Unknown';
      if (!perAffiliate.containsKey(name)) {
        perAffiliate[name] = {'amount': 0.0, 'phone': c.affiliatePhone};
      }
      perAffiliate[name]!['amount'] =
          (perAffiliate[name]!['amount'] as double) + c.commissionAmount;

      // Prefer a non-null phone if we find one
      perAffiliate[name]!['phone'] ??= c.affiliatePhone;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.dollar_circle,
                    color: Color(0xFF059669),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                const Text(
                  'Confirm Payout',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Real money will be sent to ${perAffiliate.length} affiliate(s) via mobile wallet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.55),
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── FROM: Admin's own number ──────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Iconsax.wallet_2,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FROM · Business Wallet',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.black.withValues(alpha: 0.5),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _adminPhone ?? 'Not available',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _adminPhone != null
                                    ? const Color(0xFF111827)
                                    : const Color(0xFF9CA3AF),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Arrow separator
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.arrow_down_1,
                        color: Color(0xFF059669),
                        size: 14,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── TO: Affiliate numbers ────────────────────
                if (perAffiliate.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: perAffiliate.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                      itemBuilder: (context, i) {
                        final entry = perAffiliate.entries.elementAt(i);
                        final name = entry.key;
                        final data = entry.value;
                        final phone = data['phone'] as String?;
                        final amount = data['amount'] as double;
                        final hasPhone = phone != null && phone.isNotEmpty;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF059669),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Name + phone
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111827),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    if (hasPhone)
                                      Row(
                                        children: [
                                          Icon(
                                            Iconsax.call,
                                            size: 11,
                                            color: Colors.black.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            phone,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black.withValues(
                                                alpha: 0.65,
                                              ),
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          const Icon(
                                            Iconsax.warning_2,
                                            size: 11,
                                            color: Color(0xFFDC2626),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'No phone on file',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(
                                                0xFFDC2626,
                                              ).withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),

                              // Amount
                              Text(
                                '\$${amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF059669),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // ── Total ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payout',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Confirm button ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmPayout();
                    },
                    icon: const Icon(Iconsax.send_2, size: 18),
                    label: const Text(
                      'Confirm & Send Money',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
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
      ),
    );
  }

  // ============================================================
  // FIRE THE PAYOUT
  // ============================================================
  void _confirmPayout() {
    if (_selectedIds.isEmpty) return;

    setState(() => _isPayingOut = true);

    context.read<AffiliateBloc>().add(
      PayCommissionsEvent(_selectedIds.toList()),
    );

    // Safety net — auto-dismiss after 60s
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted && _isPayingOut) {
        setState(() => _isPayingOut = false);
        _showSnack(
          'Payout is taking longer than expected. Check the backend logs.',
          isError: true,
        );
      }
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================
  void _toggleSelection(String id) {
    if (_isPayingOut) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    if (_isPayingOut) return;
    setState(() {
      final pendingIds = _cachedCommissions
          .where((c) => c.status == 'PENDING')
          .map((c) => c.id)
          .toSet();
      if (_selectedIds.length == pendingIds.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(pendingIds);
      }
    });
  }

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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case 'PENDING':
        return const _StatusStyle(
          fg: Color(0xFFD97706),
          bg: Color(0xFFFFFBEB),
          border: Color(0xFFFDE68A),
          icon: Iconsax.clock,
        );
      case 'PAID':
        return const _StatusStyle(
          fg: Color(0xFF059669),
          bg: Color(0xFFECFDF5),
          border: Color(0xFFA7F3D0),
          icon: Iconsax.tick_circle,
        );
      case 'CANCELLED':
        return const _StatusStyle(
          fg: Color(0xFFDC2626),
          bg: Color(0xFFFEF2F2),
          border: Color(0xFFFECACA),
          icon: Iconsax.close_circle,
        );
      default:
        return const _StatusStyle(
          fg: Color(0xFF6B7280),
          bg: Color(0xFFF3F4F6),
          border: Color(0xFFE5E7EB),
          icon: Iconsax.wallet_money,
        );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }
}

class _StatusStyle {
  final Color fg;
  final Color bg;
  final Color border;
  final IconData icon;
  const _StatusStyle({
    required this.fg,
    required this.bg,
    required this.border,
    required this.icon,
  });
}

// ============================================================
// BACKGROUND
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
