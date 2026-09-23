import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_event.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_state.dart';
import 'package:mobile/features/admin/presentation/screens/affiliate/admin_affiliate_settings_screen.dart';
import 'package:mobile/features/admin/presentation/screens/affiliate/affiliate_requests_screen.dart';
import 'package:mobile/features/admin/presentation/screens/affiliate/all_affiliates_screen.dart';
import 'package:mobile/features/admin/presentation/screens/affiliate/all_promo_codes_screen.dart';
import 'package:mobile/features/admin/presentation/screens/affiliate/all_commissions_screen.dart';
import 'package:iconsax/iconsax.dart';

class AdminAffiliateMarketingScreen extends StatefulWidget {
  const AdminAffiliateMarketingScreen({super.key});
  @override
  State<AdminAffiliateMarketingScreen> createState() =>
      _AffiliateMarketingScreenState();
}

class _AffiliateMarketingScreenState
    extends State<AdminAffiliateMarketingScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    context.read<AffiliateBloc>().add(FetchAffiliateDashboardEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      extendBodyBehindAppBar: true,
      body: BlocConsumer<AffiliateBloc, AffiliateState>(
        listener: (context, state) {
          if (state is AffiliateDashboardLoaded) {
            setState(() {
              _data = state.data;
              _loading = false;
            });
          } else if (state is AffiliateOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF7C3AED),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
            _load();
          }
        },
        builder: (context, state) {
          final data = _data ?? {};
          final summary =
              (data['summary'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          final topAffiliates = (data['topAffiliates'] as List?) ?? [];
          final recentCommissions = (data['recentCommissions'] as List?) ?? [];
          final monthlyStats = (data['monthlyStats'] as List?) ?? [];
          final pendingRequests =
              (data['recentRequests'] as List?)
                  ?.where((r) => r['status'] == 'PENDING')
                  .toList() ??
              [];

          return Stack(
            children: [
              const _BackgroundBlobs(),
              SafeArea(
                child: _loading && _data == null
                    ? const _LoadingState()
                    : RefreshIndicator(
                        color: const Color(0xFF7C3AED),
                        onRefresh: _load,
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            _buildHeader(),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  _buildGreetingRow(),
                                  const SizedBox(height: 24),
                                  _buildHeroGlassCard(summary),
                                  const SizedBox(height: 16),
                                  _buildStatsRow(summary, monthlyStats),
                                  const SizedBox(height: 24),
                                  _buildBentoRow(
                                    topAffiliates,
                                    pendingRequests,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildCommandGrid(),
                                  const SizedBox(height: 24),
                                  _buildRevenueChart(monthlyStats),
                                  const SizedBox(height: 24),
                                  _buildLiveFeed(recentCommissions),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================
  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      pinned: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 8),
          child: GestureDetector(
            onTap: _load,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Iconsax.refresh,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingRow() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFF59E0B)],
          ).createShader(bounds),
          child: const Text(
            'Affiliate Command',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // HERO GLASS CARD
  // ==========================================================
  Widget _buildHeroGlassCard(Map<String, dynamic> summary) {
    final totalPaid = _toD(summary['totalPaidCommissions']);
    final pending = _toD(summary['totalPendingCommissions']);
    final totalOrders = (summary['totalOrdersViaAffiliates'] ?? 0).toInt();

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: 230,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFFA855F7), Color(0xFFEC4899)],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.35),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -60,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFBEF264),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Total Paid Out',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '\$${_formatBig(totalPaid)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _miniStat(
                      Iconsax.wallet_money,
                      'Pending',
                      '\$${pending.toStringAsFixed(0)}',
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(width: 14),
                    _miniStat(
                      Iconsax.shopping_bag,
                      'Orders',
                      totalOrders.toString(),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminAllCommissionsScreen(),
                        ),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.arrow_right_2,
                          color: Color(0xFF7C3AED),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // QUICK STATS ROW
  // ==========================================================
  Widget _buildStatsRow(
    Map<String, dynamic> summary,
    List<dynamic> monthlyStats,
  ) {
    final affiliates = (summary['totalAffiliates'] ?? 0).toString();
    final pending = (summary['pendingRequests'] ?? 0).toString();
    final monthRev = monthlyStats.isNotEmpty
        ? _toD(monthlyStats.last['totalCommissions'])
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _statTile(
            icon: Iconsax.people,
            label: 'Active Affiliates',
            value: affiliates,
            color: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            icon: Iconsax.user_tick,
            label: 'Pending Requests',
            value: pending,
            color: const Color(0xFFF59E0B),
            pulse: pending != '0',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            icon: Iconsax.coin_1,
            label: 'This Month',
            value: '\$${_formatBig(monthRev)}',
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool pulse = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              if (pulse) ...[
                const SizedBox(width: 6),
                _PulsingDot(color: color),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BENTO ROW
  // ==========================================================
  Widget _buildBentoRow(
    List<dynamic> topAffiliates,
    List<dynamic> pendingRequests,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _leaderboardCard(topAffiliates)),
        const SizedBox(width: 12),
        Expanded(flex: 4, child: _pendingRequestsCard(pendingRequests)),
      ],
    );
  }

  Widget _leaderboardCard(List<dynamic> topAffiliates) {
    return Container(
      height: 340,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.crown, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Performers',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'All-time leaderboard',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminAllAffiliatesScreen()),
                ),
                child: const Icon(
                  Iconsax.arrow_right_3,
                  color: Color(0xFF9CA3AF),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (topAffiliates.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No data yet',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: math.min(3, topAffiliates.length),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final a = topAffiliates[i];
                  final name = (a['userName'] ?? 'Unknown').toString();
                  final code = (a['uniqueCode'] ?? '').toString();
                  final earnings = _toD(a['totalEarnings']);
                  final image = a['userImage']?.toString();
                  final rankColor = i == 0
                      ? const Color(0xFFFBBF24)
                      : i == 1
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFFD97706);

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(12),
                                image: image != null && image.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(image),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: image == null || image.isEmpty
                                  ? Center(
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: -3,
                              bottom: -3,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: rankColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                code,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF9CA3AF),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${_formatBig(earnings)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _pendingRequestsCard(List<dynamic> requests) {
    return Container(
      height: 340,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.clock,
                  color: Color(0xFFB45309),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    Text(
                      'Awaiting review',
                      style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            requests.length.toString(),
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: Color(0xFF78350F),
              height: 1,
              letterSpacing: -2,
            ),
          ),
          const Text(
            'new applications',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF92400E),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminAffiliateRequestsScreen(),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF78350F),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Review Now',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // COMMAND GRID — REDESIGNED (Bento 2x2, easier access)
  // ==========================================================
  Widget _buildCommandGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.grid_2,
                  color: Color(0xFF7C3AED),
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Command Center',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),

        // ── Bento 2×2 grid ────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _bentoCommandTile(
                icon: Iconsax.discount_shape,
                title: 'Promo Codes',
                subtitle: 'Manage & approve',
                colors: const [Color(0xFFEC4899), Color(0xFFF472B6)],
                badge: null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminAllPromoCodesScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bentoCommandTile(
                icon: Iconsax.people,
                title: 'Affiliates',
                subtitle: 'View all members',
                colors: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                badge: null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminAllAffiliatesScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _bentoCommandTile(
                icon: Iconsax.wallet_money,
                title: 'Payouts',
                subtitle: 'Send money',
                colors: const [Color(0xFF10B981), Color(0xFF34D399)],
                badge: null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAllCommissionsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bentoCommandTile(
                icon: Iconsax.setting_2,
                title: 'Settings',
                subtitle: 'Configure rules',
                colors: const [Color(0xFF6366F1), Color(0xFF818CF8)],
                badge: null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAffiliateSettingsScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bentoCommandTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
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
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: colors.first,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Icon(
                          Iconsax.arrow_right_3,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // REVENUE CHART — REDESIGNED (Working, interactive area chart)
  // ==========================================================
  Widget _buildRevenueChart(List<dynamic> monthlyStats) {
    final data = monthlyStats.reversed.take(6).toList().reversed.toList();

    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.chart_2,
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
                        'Commission Flow',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Monthly revenue trends',
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
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Icon(Iconsax.chart_1, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text(
                    'No data available yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Commission data will appear here',
                    style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    final values = data.map((e) => _toD(e['totalCommissions'])).toList();
    final orders = data.map((e) => (e['totalOrders'] ?? 0).toString()).toList();
    final maxVal = values.isEmpty ? 0.0 : values.reduce(math.max);
    final minVal = values.isEmpty ? 0.0 : values.reduce(math.min);
    final totalRevenue = values.fold(0.0, (sum, v) => sum + v);
    final avgRevenue = values.isEmpty ? 0.0 : totalRevenue / values.length;

    // Growth: compare first vs last
    double growth = 0.0;
    if (values.length >= 2 && values.first > 0) {
      growth = ((values.last - values.first) / values.first) * 100;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.chart_2,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Commission Flow',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last ${data.length} months',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: growth >= 0
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: growth >= 0
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : const Color(0xFFEF4444).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      growth >= 0 ? Iconsax.trend_up : Iconsax.trend_down,
                      color: growth >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: growth >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Summary stats ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF9FAFB), Colors.white],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _chartStat(
                    label: 'Total',
                    value: '\$${_formatBig(totalRevenue)}',
                    icon: Iconsax.wallet_1,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                Container(width: 1, height: 40, color: const Color(0xFFE5E7EB)),
                Expanded(
                  child: _chartStat(
                    label: 'Average',
                    value: '\$${_formatBig(avgRevenue)}',
                    icon: Iconsax.math,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                Container(width: 1, height: 40, color: const Color(0xFFE5E7EB)),
                Expanded(
                  child: _chartStat(
                    label: 'Peak',
                    value: '\$${_formatBig(maxVal)}',
                    icon: Iconsax.crown,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Chart ─────────────────────────────────────────
          SizedBox(
            height: 220,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Y-axis labels
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 30,
                      width: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${_formatBig(maxVal)}',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '\$${_formatBig((maxVal + minVal) / 2)}',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '\$${_formatBig(minVal)}',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Chart area
                    Positioned(
                      left: 44,
                      right: 0,
                      top: 0,
                      bottom: 30,
                      child: CustomPaint(
                        size: Size(chartWidth - 44, 180),
                        painter: _ModernAreaChartPainter(
                          values: values,
                          maxValue: maxVal,
                          minValue: minVal,
                          lineColor: const Color(0xFF7C3AED),
                          fillTop: const Color(0xFF7C3AED).withOpacity(0.25),
                          fillBottom: const Color(0xFF7C3AED).withOpacity(0.02),
                          gridColor: const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),

                    // Interactive dots
                    Positioned(
                      left: 44,
                      right: 0,
                      top: 0,
                      bottom: 30,
                      child: LayoutBuilder(
                        builder: (context, dotConstraints) {
                          final cw = dotConstraints.maxWidth;
                          final ch = dotConstraints.maxHeight;
                          final spacing = values.length > 1
                              ? cw / (values.length - 1)
                              : cw;

                          return Stack(
                            children: List.generate(values.length, (i) {
                              final range = (maxVal - minVal) == 0
                                  ? 1.0
                                  : (maxVal - minVal);
                              final normalized = (values[i] - minVal) / range;
                              final x = i * spacing;
                              // Map to bottom-anchored Y (inverted)
                              final y = ch - (normalized * (ch - 20)) - 10;

                              final isLast = i == values.length - 1;
                              final isFirst = i == 0;

                              return Positioned(
                                left: x - 7,
                                top: y - 7,
                                child: GestureDetector(
                                  onTap: () => _showChartTooltip(
                                    context,
                                    data[i],
                                    values[i],
                                    orders[i],
                                  ),
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: isLast || isFirst
                                          ? const Color(0xFF7C3AED)
                                          : Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFF7C3AED),
                                        width: 2.5,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: isLast
                                          ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF7C3AED,
                                                ).withOpacity(0.4),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ── X-axis labels ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(data.length, (i) {
                final monthLabel = _monthLabel(
                  data[i]['month']?.toString() ?? '',
                );
                final isLast = i == data.length - 1;
                return Text(
                  monthLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: isLast
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF9CA3AF),
                    fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  void _showChartTooltip(
    BuildContext context,
    dynamic dataPoint,
    double value,
    String orders,
  ) {
    final monthLabel = _monthLabel(dataPoint['month']?.toString() ?? '');
    final fullMonthName = _monthFullLabel(dataPoint['month']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    monthLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullMonthName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Monthly Performance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF9FAFB), Colors.white],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  _tooltipRow(
                    'Commission Earned',
                    '\$${value.toStringAsFixed(2)}',
                    const Color(0xFF7C3AED),
                    Iconsax.wallet_1,
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: const Color(0xFFE5E7EB)),
                  const SizedBox(height: 14),
                  _tooltipRow(
                    'Orders Generated',
                    orders,
                    const Color(0xFF3B82F6),
                    Iconsax.shopping_bag,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tooltipRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // LIVE FEED
  // ==========================================================
  Widget _buildLiveFeed(List<dynamic> commissions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Row(
            children: [
              const Text(
                'Live Feed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              const _PulsingDot(color: Color(0xFF10B981)),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAllCommissionsScreen(),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        if (commissions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: Text(
                'No activity yet',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ),
          )
        else
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: commissions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final c = commissions[i];
                final name = (c['affiliateName'] ?? 'Unknown').toString();
                final amount = _toD(c['commissionAmount']);
                final status = (c['status'] ?? 'PENDING').toString();
                final date = (c['createdAt'] ?? '').toString();
                final isPaid = status == 'PAID';

                return Container(
                  width: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? const Color(0xFF10B981).withOpacity(0.12)
                                  : const Color(0xFFF59E0B).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPaid ? Iconsax.tick_circle : Iconsax.clock,
                              color: isPaid
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1F2937),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _relativeDate(date),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? const Color(0xFF10B981).withOpacity(0.12)
                                  : const Color(0xFFF59E0B).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isPaid
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            '+\$${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================
  double _toD(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  String _formatBig(double v) {
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)}k';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  String _monthLabel(String ym) {
    try {
      final m = int.parse(ym.split('-')[1]);
      return ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][m -
          1];
    } catch (_) {
      return '';
    }
  }

  String _monthFullLabel(String ym) {
    try {
      final parts = ym.split('-');
      final m = int.parse(parts[1]);
      final y = parts[0];
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[m - 1]} $y';
    } catch (_) {
      return '';
    }
  }

  String _relativeDate(String d) {
    if (d.isEmpty) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(d));
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return d;
    }
  }
}

// ==========================================================
// MODERN AREA CHART PAINTER — clean, working chart
// ==========================================================
class _ModernAreaChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final double minValue;
  final Color lineColor;
  final Color fillTop;
  final Color fillBottom;
  final Color gridColor;

  _ModernAreaChartPainter({
    required this.values,
    required this.maxValue,
    required this.minValue,
    required this.lineColor,
    required this.fillTop,
    required this.fillBottom,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    // ── Grid lines ────────────────────────────────────────
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 3; i++) {
      final y = (size.height / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ── Compute points ────────────────────────────────────
    final range = (maxValue - minValue) == 0 ? 1.0 : (maxValue - minValue);
    final spacing = values.length > 1
        ? size.width / (values.length - 1)
        : size.width;

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = i * spacing;
      final normalized = (values[i] - minValue) / range;
      final y = size.height - (normalized * (size.height - 20)) - 10;
      points.add(Offset(x, y));
    }

    // ── Build smooth path ─────────────────────────────────
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cp1 = Offset(p0.dx + spacing / 3, p0.dy);
      final cp2 = Offset(p1.dx - spacing / 3, p1.dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    // ── Fill area under the curve ─────────────────────────
    final fillPath = Path.from(linePath);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.lineTo(points.first.dx, size.height);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [fillTop, fillBottom],
    );

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = fillGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    // ── Draw the line ─────────────────────────────────────
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ModernAreaChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.minValue != minValue;
  }
}

// ==========================================================
// BACKGROUND BLOBS
// ==========================================================
class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withOpacity(0.25),
                    const Color(0xFF7C3AED).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -120,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEC4899).withOpacity(0.18),
                    const Color(0xFFEC4899).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF59E0B).withOpacity(0.15),
                    const Color(0xFFF59E0B).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// GRID PAINTER (hero card decoration)
// ==========================================================
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;
    const step = 22.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================================
// PULSING DOT
// ==========================================================
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(1 - _ctrl.value),
            border: Border.all(color: widget.color, width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==========================================================
// LOADING STATE
// ==========================================================
class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF7C3AED),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading command center...',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
