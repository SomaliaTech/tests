import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_bloc.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_event.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_state.dart';

class MyCommissionsScreen extends StatefulWidget {
  const MyCommissionsScreen({super.key});

  @override
  State<MyCommissionsScreen> createState() => _MyCommissionsScreenState();
}

class _MyCommissionsScreenState extends State<MyCommissionsScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _commissions = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'ALL';

  late final AnimationController _orbController;

  @override
  void initState() {
    super.initState();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  void _load() {
    if (_commissions.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    context.read<AffiliateUserBloc>().add(const FetchMyCommissionsEvent());
  }

  // ============================================================
  // FILTER
  // ============================================================
  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'ALL') return _commissions;
    return _commissions
        .where((c) => (c['status'] ?? 'PENDING') == _filter)
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildAppBar(),
      ),
      body: Stack(
        children: [
          _CommissionsBackground(controller: _orbController),
          SafeArea(
            child: BlocConsumer<AffiliateUserBloc, AffiliateUserState>(
              listenWhen: (prev, curr) =>
                  curr is MyCommissionsLoaded || curr is AffiliateUserError,
              listener: (context, state) {
                if (!mounted) return;
                if (state is MyCommissionsLoaded) {
                  setState(() {
                    _commissions = state.commissions;
                    _isLoading = false;
                    _error = null;
                  });
                } else if (state is AffiliateUserError) {
                  setState(() {
                    _isLoading = false;
                    if (_commissions.isEmpty) _error = state.message;
                  });
                }
              },
              builder: (context, state) {
                if (_isLoading && _commissions.isEmpty) {
                  return _buildSkeleton();
                }
                if (_error != null && _commissions.isEmpty) {
                  return _buildErrorState();
                }
                if (_commissions.isEmpty) {
                  return _buildEmptyState();
                }
                return Column(
                  children: [
                    _buildSummary(),
                    _buildFilterChips(),
                    Expanded(child: _buildList()),
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
  // APP BAR
  // ============================================================
  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F).withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _glassIconButton(
                icon: Iconsax.arrow_left_2,
                onTap: () => Navigator.pop(context),
              ),
            ),
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFA78BFA),
                  Color(0xFFF472B6),
                  Color(0xFFFBBF24),
                ],
              ).createShader(bounds),
              child: const Text(
                'My Commissions',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: _glassIconButton(icon: Iconsax.refresh, onTap: _load),
              ),
            ],
          ),
        ),
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

  // ============================================================
  // SUMMARY
  // ============================================================
  Widget _buildSummary() {
    final pending = _commissions
        .where((c) => c['status'] == 'PENDING')
        .fold<double>(
          0,
          (sum, c) =>
              sum +
              (double.tryParse(c['commissionAmount']?.toString() ?? '0') ?? 0),
        );
    final paid = _commissions
        .where((c) => c['status'] == 'PAID')
        .fold<double>(
          0,
          (sum, c) =>
              sum +
              (double.tryParse(c['commissionAmount']?.toString() ?? '0') ?? 0),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.9),
                  const Color(0xFFA855F7).withValues(alpha: 0.85),
                  const Color(0xFFEC4899).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _summaryStat(
                    'Pending',
                    '\$${pending.toStringAsFixed(2)}',
                    Iconsax.clock,
                  ),
                ),
                Container(
                  width: 1,
                  height: 42,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _summaryStat(
                    'Paid',
                    '\$${paid.toStringAsFixed(2)}',
                    Iconsax.tick_circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER CHIPS
  // ============================================================
  Widget _buildFilterChips() {
    final filters = ['ALL', 'PENDING', 'PAID', 'CANCELLED'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((f) {
            final isSelected = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: -2,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _filterLabel(f),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _filterLabel(String f) {
    switch (f) {
      case 'ALL':
        return 'All';
      case 'PENDING':
        return 'Pending';
      case 'PAID':
        return 'Paid';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return f;
    }
  }

  // ============================================================
  // LIST
  // ============================================================
  Widget _buildList() {
    final items = _filtered;
    if (items.isEmpty) {
      return _buildFilterEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _load(),
      color: const Color(0xFFA855F7),
      backgroundColor: const Color(0xFF14101F),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        itemCount: items.length,
        itemBuilder: (context, i) => _buildCommissionCard(items[i]),
      ),
    );
  }

  Widget _buildCommissionCard(Map<String, dynamic> c) {
    final amount = c['commissionAmount'] ?? '0.00';
    final status = c['status'] ?? 'PENDING';
    final orderNumber = c['order']?['orderNumber'] ?? 'N/A';
    final createdAt = c['createdAt'] ?? '';
    final rate = c['commissionRate'] ?? 0;
    final orderAmount = c['orderAmount'] ?? '0.00';

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: -3,
                    ),
                  ],
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order $orderNumber',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+\$$amount',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniInfo(Iconsax.percentage_circle, '$rate% rate'),
              const SizedBox(width: 14),
              _miniInfo(Iconsax.shopping_bag, 'Order \$$orderAmount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.4)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SKELETON
  // ============================================================
  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 90, 16, 40),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _skeletonBlock(height: 96, radius: 22),
        const SizedBox(height: 12),
        _skeletonBlock(height: 44, radius: 100, width: 300),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _skeletonBlock(height: 110, radius: 20),
          ),
        ),
      ],
    );
  }

  Widget _skeletonBlock({
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
          color: Colors.white.withValues(alpha: opacity * 0.08),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================
  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.warning_2,
                  size: 36,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Failed to load',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Iconsax.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATES
  // ============================================================
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        _emptyCard(
          icon: Iconsax.wallet_money,
          title: 'No commissions yet',
          message:
              'Share your promo codes to start earning commissions on every sale.',
          color: const Color(0xFFA78BFA),
        ),
      ],
    );
  }

  Widget _buildFilterEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 40),
        _emptyCard(
          icon: Iconsax.filter,
          title: 'No ${_filterLabel(_filter).toLowerCase()} commissions',
          message: 'Try a different filter to see your earnings.',
          color: const Color(0xFFA78BFA),
        ),
      ],
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  String _formatDate(String d) {
    if (d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return d;
    }
  }
}

// ============================================================
// ANIMATED BACKGROUND
// ============================================================
class _CommissionsBackground extends StatelessWidget {
  final AnimationController controller;
  const _CommissionsBackground({required this.controller});

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
                bottom: -120 + (v * 50),
                left: -100 + (v * 60),
                child: _GlowOrb(
                  size: 350,
                  color: const Color(0xFFF59E0B),
                  opacity: 0.22,
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
