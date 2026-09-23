import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_bloc.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_event.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_state.dart';

import 'package:mobile/features/admin/presentation/screens/admin_main_navigation_screen.dart';
import 'package:mobile/features/affiliate/presentation/screens/affiliate_apply_screen.dart';
import 'package:mobile/features/affiliate/presentation/screens/affiliate_dashboard_screen.dart';
import 'package:mobile/features/auth/presentation/screens/welcome_screen.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../order/presentation/screens/order_history_screen.dart';
import '../../../profile/presentation/widgets/profile_section.dart';
import '../../../profile/presentation/widgets/logout_button.dart';
import '../../../profile/presentation/widgets/menu_item.dart';
import '../../../support/presentation/screens/support_screen.dart';
import '../../../../core/services/injection_container.dart';
import '../../../../core/services/storage/storage_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final StorageService _storageService = sl<StorageService>();

  String? _userName;
  String? _userPhone;
  String? _userProfileImage;
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  bool _isLoading = true;

  // ⭐ Affiliate state — cached locally so UI never flickers
  bool _cachedIsAffiliate = false;
  String _cachedAffiliateStatus = 'NONE';
  bool _affiliateLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCachedAffiliate();

    // Trigger user-bloc fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AffiliateUserBloc>().add(const FetchMyDashboardStatsEvent());
    });
  }

  Future<void> _loadCachedAffiliate() async {
    final isAff = await _storageService.getIsAffiliate();
    final status = await _storageService.getAffiliateStatus() ?? 'NONE';
    if (!mounted) return;
    setState(() {
      _cachedIsAffiliate = isAff;
      _cachedAffiliateStatus = status;
      _affiliateLoaded = true;
    });
  }

  Future<void> _loadUserData() async {
    try {
      final name = await _storageService.getUserName();
      final phone = await _storageService.getUserPhone();
      final profileImage = await _storageService.getUserProfileImage();
      final isAdmin = await _storageService.getIsAdmin();
      final isSuperAdmin = await _storageService.getIsSuperAdmin();

      if (!mounted) return;
      setState(() {
        _userName = name;
        _userPhone = phone;
        _userProfileImage = profileImage;
        _isAdmin = isAdmin;
        _isSuperAdmin = isSuperAdmin;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLogout(BuildContext context) {
    final authBloc = context.read<AuthBloc>();

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                  authBloc.add(LogoutEvent());
                },
                isDestructiveAction: true,
                child: const Text('Logout'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  authBloc.add(LogoutEvent());
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF4757),
                ),
                child: const Text('Logout'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            );
          }
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await _loadUserData();
                        await _loadCachedAffiliate();
                        if (!mounted) return;
                        context.read<AffiliateUserBloc>().add(
                          const FetchMyDashboardStatsEvent(),
                        );
                      },
                      color: const Color(0xFF2ED573),
                      backgroundColor: Colors.white,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            ProfileSection(
                              userName: _userName,
                              userPhone: _userPhone,
                              profileImage: _userProfileImage,
                            ),
                            const SizedBox(height: 10),
                            Container(
                              color: Colors.white,
                              child:
                                  BlocListener<
                                    AffiliateUserBloc,
                                    AffiliateUserState
                                  >(
                                    // ⭐ Only react when a REAL loaded state arrives
                                    listenWhen: (prev, curr) =>
                                        curr is MyDashboardStatsLoaded,
                                    listener: (context, state) {
                                      if (state is! MyDashboardStatsLoaded)
                                        return;
                                      // Update local cache to match bloc
                                      setState(() {
                                        _cachedIsAffiliate = state.isAffiliate;
                                        _cachedAffiliateStatus =
                                            (state.stats['status'] ?? 'NONE')
                                                .toString();
                                      });
                                    },
                                    child: _buildMenuList(),
                                  ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: LogoutButton(onTap: () => _handleLogout(context)),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
      ),
    );
  }

  Widget _buildMenuList() {
    // ⭐ Use CACHED values, never the live state directly → no flicker
    final bool isAffiliate = _cachedIsAffiliate;
    final String affiliateStatus = _cachedAffiliateStatus;
    final bool isSuspended = isAffiliate && affiliateStatus == 'SUSPENDED';
    final bool isActiveAffiliate = isAffiliate && affiliateStatus == 'ACTIVE';
    final bool isAnyAdmin = _isAdmin || _isSuperAdmin;

    // 👉 If affiliate status has never been loaded (fresh install, no cache)
    //    AND we don't know yet → hide the affiliate row entirely so no
    //    flicker between "Become" and "Dashboard".
    final bool affiliateKnown = _affiliateLoaded;

    return Column(
      children: [
        MenuItem(
          onTap: () => Navigator.push(context, OrderHistoryScreen.route()),
          id: 'order-history',
          title: 'Order history',
          icon: Iconsax.receipt,
        ),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        MenuItem(
          onTap: () => Navigator.push(context, SupportScreen.route()),
          id: 'help-center',
          title: 'Help center',
          icon: Iconsax.info_circle,
        ),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),

        // ---- Affiliate section ----
        if (!isAnyAdmin && affiliateKnown) ...[
          // Suspended
          if (isSuspended)
            MenuItem(
              onTap: () {},
              id: 'affiliate-suspended',
              title: 'Affiliate Account Suspended',
              subtitle: 'Contact support for more information',
              icon: Iconsax.warning_2,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Suspended',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Active
          if (isActiveAffiliate)
            MenuItem(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AffiliateDashboardScreen(),
                ),
              ),
              id: 'affiliate-dashboard',
              title: 'My Affiliate Dashboard',
              subtitle: 'Track earnings & promo codes',
              icon: Iconsax.chart_2,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ED573).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Color(0xFF2ED573),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Not affiliate
          if (!isAffiliate)
            MenuItem(
              onTap: () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AffiliateApplyScreen(),
                    ),
                  ).then((_) {
                    if (!mounted) return;
                    context.read<AffiliateUserBloc>().add(
                      const FetchMyDashboardStatsEvent(),
                    );
                  }),
              id: 'affiliate-apply',
              title: 'Become an Affiliate',
              subtitle: 'Earn commissions by sharing products',
              icon: Iconsax.dollar_circle,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ED573).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Earn \$',
                  style: TextStyle(
                    color: Color(0xFF2ED573),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          const Divider(height: 1, color: Color(0xFFE0E0E0)),
        ],

        // ---- Admin dashboard ----
        if (isAnyAdmin) ...[
          MenuItem(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminMainNavigationScreen(),
              ),
            ),
            id: 'admin-dashboard',
            title: _isSuperAdmin ? 'Super Admin Dashboard' : 'Admin Dashboard',
            icon: Iconsax.chart_square,
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
        ],
      ],
    );
  }
}
