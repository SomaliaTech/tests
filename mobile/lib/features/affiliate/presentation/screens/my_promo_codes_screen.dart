import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/utils/toast_helper.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_bloc.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_event.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_state.dart';
import 'package:mobile/features/affiliate/presentation/screens/create_promo_code_screen.dart';

class MyPromoCodesScreen extends StatefulWidget {
  const MyPromoCodesScreen({super.key});

  @override
  State<MyPromoCodesScreen> createState() => _MyPromoCodesScreenState();
}

class _MyPromoCodesScreenState extends State<MyPromoCodesScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _codes = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _blocSubscription;

  late final AnimationController _orbController;

  // Track in-flight actions per code
  final Set<String> _busyCodeIds = {};

  @override
  void initState() {
    super.initState();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    final currentState = context.read<AffiliateUserBloc>().state;
    if (currentState is MyPromoCodesLoaded) {
      _codes = currentState.promoCodes.map(_promoToMap).toList();
      _isLoading = false;
    } else {
      _fetchCodes();
    }

    _blocSubscription = context.read<AffiliateUserBloc>().stream.listen((
      state,
    ) {
      if (!mounted) return;

      if (state is MyPromoCodesLoaded) {
        setState(() {
          _codes = state.promoCodes.map(_promoToMap).toList();
          _isLoading = false;
          _error = null;
          _busyCodeIds.clear();
        });
      } else if (state is AffiliateUserError) {
        setState(() => _busyCodeIds.clear());
        if (_codes.isEmpty) {
          setState(() {
            _error = state.message;
            _isLoading = false;
          });
        }
        _showSnack(state.message, isError: true);
      } else if (state is AffiliateUserOperationSuccess) {
        _showSnack(state.message, isError: false);
        _fetchCodes();
      }
    });
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

  @override
  void dispose() {
    _blocSubscription?.cancel();
    _orbController.dispose();
    super.dispose();
  }

  void _fetchCodes() {
    if (_codes.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    context.read<AffiliateUserBloc>().add(const FetchMyPromoCodesEvent());
  }

  void _deletePromoCode(String id) {
    setState(() => _busyCodeIds.add(id));
    context.read<AffiliateUserBloc>().add(
      DeleteMyPromoCodeEvent(promoCodeId: id),
    );
  }

  void _toggleCode(String id, bool currentStatus) {
    setState(() => _busyCodeIds.add(id));
    context.read<AffiliateUserBloc>().add(
      ToggleMyPromoCodeEvent(promoCodeId: id, isActive: !currentStatus),
    );
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
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================
  void _showDeleteConfirmation(Map<String, dynamic> code) {
    final codeValue = code['code'] ?? '';
    final discountType = code['discountType'] ?? 'PERCENTAGE';
    final discountValue = code['discountValue'] ?? 0;
    final isActive = code['isActive'] ?? false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF14101F).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFEF4444,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Iconsax.trash,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Delete Promo Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Are you sure you want to permanently delete this promo code?',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              discountType == 'PERCENTAGE'
                                  ? '$discountValue%'
                                  : '\$$discountValue',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                codeValue,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 1,
                                ),
                              ),
                              if (!isActive) ...[
                                const SizedBox(height: 3),
                                const Text(
                                  'Pending Approval',
                                  style: TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.info_circle,
                          color: Color(0xFFFBBF24),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This action cannot be undone.',
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
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _deletePromoCode(code['id']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
          _PromoBackground(controller: _orbController),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _fetchCodes(),
              color: const Color(0xFFA855F7),
              backgroundColor: const Color(0xFF14101F),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

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
                'My Promo Codes',
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
                child: _glassIconButton(
                  icon: Iconsax.add_circle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreatePromoCodeScreen(),
                    ),
                  ).then((_) => _fetchCodes()),
                  accent: true,
                ),
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
    bool accent = false,
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
              gradient: accent
                  ? const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                    )
                  : null,
              color: accent ? null : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: accent
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _codes.isEmpty) {
      return _buildSkeleton();
    }

    if (_error != null && _codes.isEmpty) {
      return _buildErrorState();
    }

    if (_codes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: _codes.length,
      itemBuilder: (context, index) => _buildPromoCodeCard(_codes[index]),
    );
  }

  // ============================================================
  // LOADING SKELETON
  // ============================================================
  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: 4,
      itemBuilder: (context, index) => _skeletonCard(),
    );
  }

  Widget _skeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _skeletonBox(width: 64, height: 64, radius: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBox(width: 120, height: 16, radius: 6),
                    const SizedBox(height: 8),
                    _skeletonBox(width: 80, height: 12, radius: 6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _skeletonBox(height: 36, radius: 10)),
              const SizedBox(width: 8),
              Expanded(child: _skeletonBox(height: 36, radius: 10)),
              const SizedBox(width: 8),
              Expanded(child: _skeletonBox(height: 36, radius: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox({
    double? width,
    required double height,
    double radius = 8,
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
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchCodes,
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
  // EMPTY STATE
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
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                      blurRadius: 28,
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.discount_shape,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'No promo codes yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first promo code and start earning commissions today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreatePromoCodeScreen(),
                    ),
                  ).then((_) => _fetchCodes()),
                  icon: const Icon(Iconsax.add_circle, size: 18),
                  label: const Text(
                    'Create First Code',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
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
  // PROMO CODE CARD
  // ============================================================
  Widget _buildPromoCodeCard(Map<String, dynamic> code) {
    final id = code['id']?.toString() ?? '';
    final codeValue = code['code'] ?? '';
    final discountType = code['discountType'] ?? 'PERCENTAGE';
    final discountValue = code['discountValue'] ?? 0;
    final usedCount = code['usedCount'] ?? 0;
    final maxUses = code['maxUses'];
    final isActive = code['isActive'] ?? true;
    final expiresAt = code['expiresAt'];
    final isPending = !isActive;
    final isBusy = _busyCodeIds.contains(id);

    final accentColor = isPending
        ? const Color(0xFFFBBF24)
        : const Color(0xFF34D399);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isBusy ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isPending
                ? const Color(0xFFFBBF24).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // ---- Header ----
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: isPending
                          ? const LinearGradient(
                              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isPending
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFF7C3AED))
                                  .withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          discountValue.toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          discountType == 'PERCENTAGE' ? '% OFF' : '\$ OFF',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
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
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
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
                        const SizedBox(height: 6),
                        Text(
                          '$usedCount${maxUses != null ? '/$maxUses' : ''} uses',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (expiresAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Expires ${_formatDate(expiresAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---- Pending banner ----
            if (isPending)
              Container(
                margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.clock,
                      color: Color(0xFFFBBF24),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Awaiting admin approval',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ---- Divider ----
            Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),

            // ---- Actions ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: isBusy
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFFA78BFA),
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        _actionButton(
                          icon: Iconsax.copy,
                          label: 'Copy',
                          color: const Color(0xFF60A5FA),
                          onTap: () => _copyToClipboard(codeValue),
                        ),
                        _actionButton(
                          icon: Iconsax.share,
                          label: 'Share',
                          color: const Color(0xFFA78BFA),
                          onTap: () => _shareCode(
                            codeValue,
                            discountValue,
                            discountType,
                          ),
                        ),
                        _actionButton(
                          icon: isActive ? Iconsax.eye_slash : Iconsax.eye,
                          label: isActive ? 'Disable' : 'Enable',
                          color: isActive
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF34D399),
                          onTap: () => _toggleCode(id, isActive),
                        ),
                        _actionButton(
                          icon: Iconsax.trash,
                          label: 'Delete',
                          color: const Color(0xFFEF4444),
                          onTap: () => _showDeleteConfirmation(code),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('Code "$text" copied!', isError: false);
  }

  void _shareCode(String code, dynamic discount, String type) {
    final message = type == 'PERCENTAGE'
        ? 'Use my code "$code" to get $discount% OFF! 🎉'
        : 'Use my code "$code" to get \$$discount OFF! 🎉';
    Clipboard.setData(ClipboardData(text: message));
    _showSnack('Share message copied!', isError: false);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }
}

// ============================================================
// ANIMATED BACKGROUND
// ============================================================
class _PromoBackground extends StatelessWidget {
  final AnimationController controller;
  const _PromoBackground({required this.controller});

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
                  color: const Color(0xFFEC4899),
                  opacity: 0.28,
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
