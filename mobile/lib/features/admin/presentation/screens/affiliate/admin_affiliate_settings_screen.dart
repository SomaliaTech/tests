// lib/features/admin/presentation/screens/affiliate/admin_affiliate_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/utils/toast_helper.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_event.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_state.dart';

class AdminAffiliateSettingsScreen extends StatefulWidget {
  const AdminAffiliateSettingsScreen({super.key});

  @override
  State<AdminAffiliateSettingsScreen> createState() =>
      _AdminAffiliateSettingsScreenState();
}

class _AdminAffiliateSettingsScreenState
    extends State<AdminAffiliateSettingsScreen>
    with SingleTickerProviderStateMixin {
  // ── Local editable state ───────────────────────────────
  double _defaultCommissionRate = 5.0;
  double _minPayoutAmount = 10.0;
  int _payoutCycleDays = 30;

  String _defaultDiscountType = 'PERCENTAGE';
  double _defaultDiscountValue = 5.0;
  int _defaultMaxUsesPerUser = 1;

  bool _requireApproval = true;
  bool _autoApprovePromoCodes = false;
  bool _allowSelfReferral = false;
  int _cookieWindowDays = 30;

  bool _notifyOnNewApplication = true;
  bool _notifyOnNewCommission = true;
  bool _notifyOnCodeApproval = true;
  bool _emailDigest = false;

  // ── UI state ───────────────────────────────────────────
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _hasLoadedOnce = false;

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // ✅ Fetch settings on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchSettings();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _fetchSettings() {
    if (!_hasLoadedOnce) setState(() => _isLoading = true);
    context.read<AffiliateBloc>().add(const FetchAffiliateSettingsEvent());
  }

  void _applySettings(Map<String, dynamic> s) {
    _defaultCommissionRate =
        (s['defaultCommissionRate'] as num?)?.toDouble() ?? 5.0;
    _minPayoutAmount = (s['minPayoutAmount'] as num?)?.toDouble() ?? 10.0;
    _payoutCycleDays = (s['payoutCycleDays'] as num?)?.toInt() ?? 30;

    _defaultDiscountType = s['defaultDiscountType']?.toString() ?? 'PERCENTAGE';
    _defaultDiscountValue =
        (s['defaultDiscountValue'] as num?)?.toDouble() ?? 5.0;
    _defaultMaxUsesPerUser = (s['defaultMaxUsesPerUser'] as num?)?.toInt() ?? 1;

    _requireApproval = s['requireApproval'] as bool? ?? true;
    _autoApprovePromoCodes = s['autoApprovePromoCodes'] as bool? ?? false;
    _allowSelfReferral = s['allowSelfReferral'] as bool? ?? false;
    _cookieWindowDays = (s['cookieWindowDays'] as num?)?.toInt() ?? 30;

    _notifyOnNewApplication = s['notifyOnNewApplication'] as bool? ?? true;
    _notifyOnNewCommission = s['notifyOnNewCommission'] as bool? ?? true;
    _notifyOnCodeApproval = s['notifyOnCodeApproval'] as bool? ?? true;
    _emailDigest = s['emailDigest'] as bool? ?? false;

    _isLoading = false;
    _hasLoadedOnce = true;
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  // ============================================================
  // SAVE
  // ============================================================
  void _save() {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'defaultCommissionRate': _defaultCommissionRate,
      'minPayoutAmount': _minPayoutAmount,
      'payoutCycleDays': _payoutCycleDays,
      'defaultDiscountType': _defaultDiscountType,
      'defaultDiscountValue': _defaultDiscountValue,
      'defaultMaxUsesPerUser': _defaultMaxUsesPerUser,
      'requireApproval': _requireApproval,
      'autoApprovePromoCodes': _autoApprovePromoCodes,
      'allowSelfReferral': _allowSelfReferral,
      'cookieWindowDays': _cookieWindowDays,
      'notifyOnNewApplication': _notifyOnNewApplication,
      'notifyOnNewCommission': _notifyOnNewCommission,
      'notifyOnCodeApproval': _notifyOnCodeApproval,
      'emailDigest': _emailDigest,
    };

    context.read<AffiliateBloc>().add(SaveAffiliateSettingsEvent(data));
  }

  void _resetDefaults() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
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
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.refresh_circle,
                  color: Color(0xFFDC2626),
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Reset to Defaults?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will reset all fields to their default values. You still need to tap Save to persist.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                        side: BorderSide(
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                        setState(() {
                          _defaultCommissionRate = 5.0;
                          _minPayoutAmount = 10.0;
                          _payoutCycleDays = 30;
                          _defaultDiscountType = 'PERCENTAGE';
                          _defaultDiscountValue = 5.0;
                          _defaultMaxUsesPerUser = 1;
                          _requireApproval = true;
                          _autoApprovePromoCodes = false;
                          _allowSelfReferral = false;
                          _cookieWindowDays = 30;
                          _notifyOnNewApplication = true;
                          _notifyOnNewCommission = true;
                          _notifyOnCodeApproval = true;
                          _emailDigest = false;
                          _hasChanges = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Reset',
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
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _SoftBackground(controller: _bgController),
          SafeArea(
            child: BlocConsumer<AffiliateBloc, AffiliateState>(
              listenWhen: (prev, curr) =>
                  curr is AffiliateSettingsLoaded ||
                  curr is AffiliateSettingsSaved ||
                  curr is AffiliateError ||
                  curr is AffiliateSettingsSaving,
              listener: (context, state) {
                if (!mounted) return;

                if (state is AffiliateSettingsLoaded) {
                  setState(() {
                    _applySettings(state.settings);
                    _isSaving = false;
                  });
                } else if (state is AffiliateSettingsSaved) {
                  setState(() {
                    _applySettings(state.settings);
                    _isSaving = false;
                    _hasChanges = false;
                  });
                  ToastHelper.showSuccess(context, 'Settings saved');
                } else if (state is AffiliateSettingsSaving) {
                  setState(() => _isSaving = true);
                } else if (state is AffiliateError) {
                  setState(() => _isSaving = false);
                  ToastHelper.showError(context, state.message);
                }
              },
              builder: (context, state) {
                // First-load skeleton
                if (_isLoading && !_hasLoadedOnce) {
                  return _buildSkeleton();
                }

                // Error with no data
                if (state is AffiliateError && !_hasLoadedOnce) {
                  return _buildErrorState(state.message);
                }

                // Main content
                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                  children: [
                    _buildSectionHeader(
                      'Commission Defaults',
                      'Applied to new affiliates',
                      Iconsax.percentage_circle,
                      const Color(0xFF7C3AED),
                    ),
                    _buildCard(
                      children: [
                        _buildSliderTile(
                          label: 'Default Commission Rate',
                          value: _defaultCommissionRate,
                          min: 0,
                          max: 50,
                          divisions: 100,
                          suffix: '%',
                          onChanged: (v) {
                            setState(() => _defaultCommissionRate = v);
                            _markChanged();
                          },
                        ),
                        const _Divider(),
                        _buildNumberField(
                          key: const ValueKey('minPayout'),
                          label: 'Minimum Payout Amount',
                          value: _minPayoutAmount,
                          prefix: '\$',
                          onChanged: (v) {
                            _minPayoutAmount = v;
                            _markChanged();
                          },
                        ),
                        const _Divider(),
                        _buildChoiceTile(
                          label: 'Payout Cycle',
                          subtitle: 'How often affiliates get paid',
                          value: '$_payoutCycleDays days',
                          options: const [7, 14, 30, 60],
                          onSelect: (days) {
                            setState(() => _payoutCycleDays = days);
                            _markChanged();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader(
                      'Promo Code Defaults',
                      'Pre-filled when creating codes',
                      Iconsax.discount_shape,
                      const Color(0xFFEC4899),
                    ),
                    _buildCard(
                      children: [
                        _buildSegmentedToggle(
                          label: 'Default Discount Type',
                          options: const {
                            'PERCENTAGE': '% Percentage',
                            'FIXED': '\$ Fixed',
                          },
                          selected: _defaultDiscountType,
                          onSelect: (v) {
                            setState(() => _defaultDiscountType = v);
                            _markChanged();
                          },
                        ),
                        const _Divider(),
                        _buildNumberField(
                          key: const ValueKey('discountValue'),
                          label: 'Default Discount Value',
                          value: _defaultDiscountValue,
                          prefix: _defaultDiscountType == 'PERCENTAGE'
                              ? '%'
                              : '\$',
                          onChanged: (v) {
                            _defaultDiscountValue = v;
                            _markChanged();
                          },
                        ),
                        const _Divider(),
                        _buildCounterTile(
                          label: 'Max Uses Per User',
                          subtitle:
                              'How many times one customer can use a code',
                          value: _defaultMaxUsesPerUser,
                          min: 1,
                          max: 10,
                          onChanged: (v) {
                            setState(() => _defaultMaxUsesPerUser = v);
                            _markChanged();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader(
                      'Program Rules',
                      'Control the affiliate lifecycle',
                      Iconsax.shield_tick,
                      const Color(0xFF3B82F6),
                    ),
                    _buildCard(
                      children: [
                        _buildSwitchTile(
                          label: 'Require Admin Approval',
                          subtitle:
                              'New affiliate applications need manual review',
                          value: _requireApproval,
                          onChanged: (v) {
                            setState(() => _requireApproval = v);
                            _markChanged();
                          },
                        ),
                        const _Divider(),
                        _buildSwitchTile(
                          label: 'Auto-Approve Promo Codes',
                          subtitle:
                              'Affiliate codes go live without admin review',
                          value: _autoApprovePromoCodes,
                          onChanged: (v) {
                            setState(() => _autoApprovePromoCodes = v);
                            _markChanged();
                          },
                        ),
                        const _Divider(),
                        _buildSwitchTile(
                          label: 'Allow Self-Referral',
                          subtitle:
                              'Affiliates can use their own codes for discounts',
                          value: _allowSelfReferral,
                          onChanged: (v) {
                            setState(() => _allowSelfReferral = v);
                            _markChanged();
                          },
                        ),
                        const _Divider(),
                        _buildCounterTile(
                          label: 'Cookie Window',
                          subtitle:
                              'Days an affiliate is credited after a click',
                          value: _cookieWindowDays,
                          min: 1,
                          max: 90,
                          suffix: 'd',
                          onChanged: (v) {
                            setState(() => _cookieWindowDays = v);
                            _markChanged();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader(
                      'Notifications',
                      'Choose what you want to be alerted about',
                      Iconsax.notification,
                      const Color(0xFFF59E0B),
                    ),
                    _buildCard(
                      children: [
                        _buildSwitchTile(
                          label: 'New Applications',
                          subtitle:
                              'Get notified when a user applies to become an affiliate',
                          value: _notifyOnNewApplication,
                          onChanged: (v) {
                            setState(() => _notifyOnNewApplication = v);
                            _markChanged();
                          },
                        ),
                        const _Divider(),
                        _buildSwitchTile(
                          label: 'New Commissions',
                          subtitle:
                              'Get notified each time an affiliate earns a commission',
                          value: _notifyOnNewCommission,
                          onChanged: (v) {
                            setState(() => _notifyOnNewCommission = v);
                            _markChanged();
                          },
                        ),
                        const _Divider(),
                        _buildSwitchTile(
                          label: 'Promo Code Approvals',
                          subtitle:
                              'Get notified when an affiliate submits a code',
                          value: _notifyOnCodeApproval,
                          onChanged: (v) {
                            setState(() => _notifyOnCodeApproval = v);
                            _markChanged();
                          },
                        ),
                        const _Divider(),
                        _buildSwitchTile(
                          label: 'Weekly Email Digest',
                          subtitle: 'Receive a weekly summary every Monday',
                          value: _emailDigest,
                          onChanged: (v) {
                            setState(() => _emailDigest = v);
                            _markChanged();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader(
                      'Danger Zone',
                      'Irreversible actions',
                      Iconsax.warning_2,
                      const Color(0xFFDC2626),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFDC2626,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Iconsax.refresh_circle,
                                  color: Color(0xFFDC2626),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reset Settings',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Restore all settings to their default values',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _resetDefaults,
                              icon: const Icon(Iconsax.refresh, size: 16),
                              label: const Text(
                                'Reset to Defaults',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(
                                  color: Color(0xFFDC2626),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),

          if (_hasChanges && !_isLoading) _buildStickySaveBar(),
        ],
      ),
    );
  }

  // ============================================================
  // SKELETON
  // ============================================================
  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _skeletonBox(height: 60, radius: 12),
        const SizedBox(height: 12),
        _skeletonBox(height: 240, radius: 20),
        const SizedBox(height: 24),
        _skeletonBox(height: 60, radius: 12),
        const SizedBox(height: 12),
        _skeletonBox(height: 240, radius: 20),
        const SizedBox(height: 24),
        _skeletonBox(height: 60, radius: 12),
        const SizedBox(height: 12),
        _skeletonBox(height: 300, radius: 20),
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
  // ERROR
  // ============================================================
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              'Failed to load settings',
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
              onPressed: _fetchSettings,
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
                      'Affiliate Settings',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  if (_hasChanges && !_isSaving && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFBBF24,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.info_circle,
                              size: 12,
                              color: Color(0xFFD97706),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Unsaved',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
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
  // STICKY SAVE BAR
  // ============================================================
  Widget _buildStickySaveBar() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Unsaved changes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    'Tap Save to apply',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      // Reload from server to discard local changes
                      _fetchSettings();
                      setState(() => _hasChanges = false);
                    },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
              ),
              child: const Text(
                'Discard',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Iconsax.tick_circle, size: 16),
              label: Text(
                _isSaving ? 'Saving…' : 'Save',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFF111827,
                ).withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
  // SECTION HEADER + CARD WRAPPER
  // ============================================================
  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ============================================================
  // TILES (unchanged from before)
  // ============================================================
  Widget _buildSwitchTile({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF111827),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)}$suffix',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF7C3AED),
              inactiveTrackColor: const Color(0xFFE5E7EB),
              thumbColor: const Color(0xFF7C3AED),
              overlayColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required Key key,
    required String label,
    required double value,
    required String prefix,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            height: 44,
            child: TextFormField(
              initialValue: value.toString(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
              decoration: InputDecoration(
                prefixText: prefix,
                prefixStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF7C3AED),
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null && parsed >= 0) onChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterTile({
    required String label,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    String suffix = '',
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _counterBtn(
                  icon: Iconsax.minus,
                  enabled: value > min,
                  onTap: () => onChanged(value - 1),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$value$suffix',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                _counterBtn(
                  icon: Iconsax.add,
                  enabled: value < max,
                  onTap: () => onChanged(value + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 14,
          color: enabled
              ? const Color(0xFF111827)
              : Colors.black.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildChoiceTile({
    required String label,
    required String subtitle,
    required String value,
    required List<int> options,
    required ValueChanged<int> onSelect,
  }) {
    return GestureDetector(
      onTap: () {
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
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...options.map((days) {
                    final isSelected = value == '$days days';
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelect(days);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF111827)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF111827)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$days days',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Iconsax.tick_circle,
                                color: Colors.white,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Iconsax.arrow_down_1,
                    size: 12,
                    color: Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedToggle({
    required String label,
    required Map<String, String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: options.entries.map((e) {
                final isSelected = e.key == selected;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelect(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? const Color(0xFF111827)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DIVIDER
// ============================================================
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.black.withValues(alpha: 0.05),
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
