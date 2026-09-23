import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_bloc.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_event.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_state.dart';
import 'package:mobile/features/affiliate/presentation/screens/my_promo_codes_screen.dart';
import 'package:mobile/features/affiliate/presentation/screens/my_commissions_screen.dart';
import 'package:mobile/features/affiliate/presentation/screens/create_promo_code_screen.dart';

class AffiliateDashboardScreen extends StatefulWidget {
  const AffiliateDashboardScreen({super.key});

  @override
  State<AffiliateDashboardScreen> createState() =>
      _AffiliateDashboardScreenState();
}

class _AffiliateDashboardScreenState extends State<AffiliateDashboardScreen>
    with TickerProviderStateMixin {
  // Local cache
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _codes = [];
  List<Map<String, dynamic>> _commissions = [];

  // Load flags — separate so we can show partial UI
  bool _loadingStats = true;
  bool _loadingCodes = true;
  bool _loadingCommissions = true;
  bool _hasError = false;
  String _errorMessage = '';

  StreamSubscription? _blocSubscription;

  // Animations
  late final AnimationController _orbController;
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<double> _statsFade;
  late final Animation<double> _codesFade;
  late final Animation<double> _commissionsFade;

  @override
  void initState() {
    super.initState();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerFade = _makeInterval(0.0, 0.4);
    _statsFade = _makeInterval(0.15, 0.6);
    _codesFade = _makeInterval(0.3, 0.75);
    _commissionsFade = _makeInterval(0.45, 0.9);

    _initData();
  }

  Animation<double> _makeInterval(double begin, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  void _initData() {
    final currentState = context.read<AffiliateUserBloc>().state;

    // Hydrate from current state if available
    if (currentState is MyDashboardStatsLoaded) {
      _stats = currentState.stats;
      _loadingStats = false;
    }
    if (currentState is MyPromoCodesLoaded) {
      _codes = currentState.promoCodes.map(_promoToMap).toList();
      _loadingCodes = false;
    }
    if (currentState is MyCommissionsLoaded) {
      _commissions = currentState.commissions;
      _loadingCommissions = false;
    }

    // If we already have data, no need to wait
    if (!_loadingStats && !_loadingCodes && !_loadingCommissions) {
      _entranceController.forward();
    }

    _fetchAllData();

    // Subscribe to future updates
    _blocSubscription = context.read<AffiliateUserBloc>().stream.listen((
      state,
    ) {
      if (!mounted) return;

      if (state is MyDashboardStatsLoaded) {
        setState(() {
          _stats = state.stats;
          _loadingStats = false;
          _hasError = false;
        });
        _tryStartEntrance();
      } else if (state is MyPromoCodesLoaded) {
        setState(() {
          _codes = state.promoCodes.map(_promoToMap).toList();
          _loadingCodes = false;
        });
        _tryStartEntrance();
      } else if (state is MyCommissionsLoaded) {
        setState(() {
          _commissions = state.commissions;
          _loadingCommissions = false;
        });
        _tryStartEntrance();
      } else if (state is AffiliateUserOperationSuccess) {
        _showSnack(state.message, isError: false);
        _fetchAllData();
      } else if (state is AffiliateUserError) {
        setState(() {
          _loadingStats = false;
          _loadingCodes = false;
          _loadingCommissions = false;
          _hasError = true;
          _errorMessage = state.message;
        });
        _tryStartEntrance();
      }
    });
  }

  void _tryStartEntrance() {
    if (!_entranceController.isAnimating && _entranceController.value == 0.0) {
      _entranceController.forward();
    }
  }

  Map<String, dynamic> _promoToMap(dynamic entity) {
    if (entity is Map<String, dynamic>) return entity;
    return {
      'id': entity.id,
      'code': entity.code,
      'discountType': entity.discountType,
      'discountValue': entity.discountValue,
      'usedCount': entity.usedCount,
      'maxUses': entity.maxUses,
      'isActive': entity.isActive,
      'expiresAt': entity.expiresAt?.toIso8601String(),
      'totalRevenue': entity.totalRevenue,
    };
  }

  void _fetchAllData() {
    final bloc = context.read<AffiliateUserBloc>();
    bloc.add(const FetchMyDashboardStatsEvent());
    bloc.add(const FetchMyPromoCodesEvent());
    bloc.add(const FetchMyCommissionsEvent());
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _blocSubscription?.cancel();
    _orbController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          _DashboardBackground(controller: _orbController),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _loadingStats = true;
                        _loadingCodes = true;
                        _loadingCommissions = true;
                        _hasError = false;
                      });
                      _fetchAllData();
                    },
                    color: const Color(0xFFA855F7),
                    backgroundColor: const Color(0xFF14101F),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fadeSlide(_headerFade, _buildWelcomeBlock()),
                          const SizedBox(height: 20),
                          _fadeSlide(_statsFade, _buildEarningsHero()),
                          const SizedBox(height: 16),
                          _fadeSlide(_statsFade, _buildStatsGrid()),
                          const SizedBox(height: 24),
                          _fadeSlide(_codesFade, _buildPromoCodesSection()),
                          const SizedBox(height: 24),
                          _fadeSlide(
                            _commissionsFade,
                            _buildRecentCommissions(),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _fadeSlide(Animation<double> anim, Widget child) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - anim.value)),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _glassIconButton(
            icon: Iconsax.arrow_left_2,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFA78BFA),
                      Color(0xFFF472B6),
                      Color(0xFFFBBF24),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'Affiliate Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Track your earnings & codes',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _glassIconButton(
            icon: Iconsax.refresh,
            onTap: () {
              setState(() {
                _loadingStats = true;
                _loadingCodes = true;
                _loadingCommissions = true;
                _hasError = false;
              });
              _fetchAllData();
            },
          ),
        ],
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFA78BFA), Color(0xFFF472B6), Color(0xFFFBBF24)],
          ).createShader(bounds),
          child: const Text(
            'Your Earnings Hub',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  // ============================================================
  // EARNINGS HERO
  // ============================================================
  Widget _buildEarningsHero() {
    if (_loadingStats) {
      return _skeletonHero();
    }

    final total = _stats['totalEarnings'] ?? '0.00';
    final pending = _stats['pendingEarnings'] ?? '0.00';
    final paid = _stats['paidEarnings'] ?? '0.00';

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF7C3AED).withValues(alpha: 0.95),
                const Color(0xFFA855F7).withValues(alpha: 0.9),
                const Color(0xFFEC4899).withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                blurRadius: 32,
                offset: const Offset(0, 16),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative orbs
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.wallet_2,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Total Earnings',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF34D399),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '\$${_formatMoney(total)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _heroMiniStat(
                          'Pending',
                          '\$${_formatMoney(pending)}',
                          Iconsax.clock,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _heroMiniStat(
                          'Paid',
                          '\$${_formatMoney(paid)}',
                          Iconsax.tick_circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroMiniStat(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.75)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS GRID
  // ============================================================
  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _loadingStats
              ? _skeletonStatCard()
              : _statCard(
                  'Orders',
                  (_stats['totalOrders'] ?? 0).toString(),
                  Iconsax.shopping_bag,
                  const Color(0xFF60A5FA),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _loadingStats
              ? _skeletonStatCard()
              : _statCard(
                  'Rate',
                  '${_stats['commissionRate'] ?? '5'}%',
                  Iconsax.percentage_circle,
                  const Color(0xFFF472B6),
                ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROMO CODES
  // ============================================================
  Widget _buildPromoCodesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'My Promo Codes',
          onTapViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyPromoCodesScreen()),
          ).then((_) => _fetchAllData()),
        ),
        const SizedBox(height: 14),
        if (_loadingCodes)
          _skeletonListTile()
        else if (_codes.isEmpty)
          _emptyState(
            icon: Iconsax.discount_shape,
            title: 'No promo codes yet',
            message: 'Create your first code to start earning',
            accentColor: const Color(0xFFA78BFA),
          )
        else
          ..._codes.take(3).map(_buildPromoCodeCard),
      ],
    );
  }

  Widget _buildPromoCodeCard(Map<String, dynamic> code) {
    final codeValue = code['code'] ?? '';
    final discountType = code['discountType'] ?? 'PERCENTAGE';
    final discountValue = code['discountValue'] ?? 0;
    final usedCount = code['usedCount'] ?? 0;
    final isActive = code['isActive'] ?? true;
    final totalRevenue = code['totalRevenue'] ?? '0.00';

    final isPending = !isActive;
    final accentColor = isPending
        ? const Color(0xFFFBBF24)
        : const Color(0xFF34D399);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? const Color(0xFFFBBF24).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: isPending
                      ? const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                        ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isPending
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFF7C3AED))
                              .withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    discountType == 'PERCENTAGE'
                        ? '$discountValue%'
                        : '\$$discountValue',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            codeValue,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isActive ? 'ACTIVE' : 'PENDING',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: accentColor,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPending
                          ? 'Awaiting approval'
                          : '$usedCount uses · \$${_formatMoney(totalRevenue)} earned',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _copyCode(codeValue),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Icon(
                    Iconsax.copy,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.info_circle,
                    color: Color(0xFFFBBF24),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Will be activated after admin approval',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // RECENT COMMISSIONS
  // ============================================================
  Widget _buildRecentCommissions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Recent Commissions',
          onTapViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyCommissionsScreen()),
          ).then((_) => _fetchAllData()),
        ),
        const SizedBox(height: 14),
        if (_loadingCommissions)
          _skeletonListTile()
        else if (_commissions.isEmpty)
          _emptyState(
            icon: Iconsax.wallet_money,
            title: 'No commissions yet',
            message: 'Share your codes to start earning',
            accentColor: const Color(0xFF34D399),
          )
        else
          ..._commissions.take(5).map(_buildCommissionItem),
      ],
    );
  }

  Widget _buildCommissionItem(Map<String, dynamic> commission) {
    final amount = commission['commissionAmount'] ?? '0.00';
    final status = commission['status'] ?? 'PENDING';
    final orderNumber = commission['order']?['orderNumber'] ?? 'N/A';
    final createdAt = commission['createdAt'] ?? '';

    final statusColor = status == 'PAID'
        ? const Color(0xFF34D399)
        : status == 'PENDING'
        ? const Color(0xFFFBBF24)
        : const Color(0xFFEF4444);

    final statusIcon = status == 'PAID'
        ? Iconsax.tick_circle
        : status == 'PENDING'
        ? Iconsax.clock
        : Iconsax.close_circle;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+\$${_formatMoney(amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: statusColor,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHARED UI
  // ============================================================
  Widget _sectionHeader(String title, {required VoidCallback onTapViewAll}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTapViewAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'View all',
                  style: TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Iconsax.arrow_right_3,
                  color: const Color(0xFFA78BFA),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonHero() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Center(child: _PulsingLoader()),
    );
  }

  Widget _skeletonStatCard() {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
    );
  }

  Widget _skeletonListTile() {
    return Container(
      height: 74,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFA78BFA),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePromoCodeScreen()),
          ).then((_) => _fetchAllData());
        },
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Iconsax.add_circle, color: Colors.white, size: 20),
        label: const Text(
          'Create Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    _showSnack('Code "$code" copied!', isError: false);
  }

  String _formatMoney(dynamic v) {
    if (v == null) return '0.00';
    final n = double.tryParse(v.toString()) ?? 0.0;
    return n.toStringAsFixed(2);
  }

  String _formatDate(String d) {
    if (d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return d;
    }
  }
}

// ============================================================
// BACKGROUND
// ============================================================
class _DashboardBackground extends StatelessWidget {
  final AnimationController controller;
  const _DashboardBackground({required this.controller});

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
              colors: [Color(0xFF0A0A0F), Color(0xFF14101F)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -100 + (v * 60),
                right: -120 + (v * 40),
                child: _GlowOrb(
                  size: 400,
                  color: const Color(0xFF7C3AED),
                  opacity: 0.35,
                ),
              ),
              Positioned(
                top: 300 - (v * 50),
                left: -160 + (v * 30),
                child: _GlowOrb(
                  size: 380,
                  color: const Color(0xFFEC4899),
                  opacity: 0.28,
                ),
              ),
              Positioned(
                bottom: 100 + (v * 40),
                right: -100 - (v * 30),
                child: _GlowOrb(
                  size: 320,
                  color: const Color(0xFFF59E0B),
                  opacity: 0.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb({
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

// ============================================================
// PULSING LOADER
// ============================================================
class _PulsingLoader extends StatefulWidget {
  const _PulsingLoader();

  @override
  State<_PulsingLoader> createState() => _PulsingLoaderState();
}

class _PulsingLoaderState extends State<_PulsingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Opacity(
          opacity: 0.4 + (_c.value * 0.6),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFA78BFA).withValues(alpha: 0.2),
              border: Border.all(color: const Color(0xFFA78BFA), width: 2),
            ),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFA78BFA),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
