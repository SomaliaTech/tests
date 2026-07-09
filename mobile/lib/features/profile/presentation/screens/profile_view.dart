import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/error/error_handler.dart';
import 'package:mobile/features/profile/domain/entities/market.dart';
import 'package:mobile/features/profile/domain/entities/profile.dart';
import 'package:mobile/features/profile/domain/usecases/get_markets.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/profile_form.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/warning_section.dart';
import '../widgets/market_dropdown.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/services/injection_container.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isMarketDropdownOpen = false;
  List<Market> _markets = [];
  Market? _selectedMarket;
  String _name = '';
  String _email = '';
  String? _currentMarketId;
  bool _marketsLoaded = false;
  bool _profileLoaded = false;
  bool _isInitializing = true;
  static const String _whatsappNumber = '+252686330033';

  // ✅ Store the current profile
  Profile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    context.read<ProfileBloc>().add(LoadProfileEvent());
    await _loadMarkets();

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri whatsappUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: _whatsappNumber,
      queryParameters: {'text': 'Asc! Waxan rabaa cawinaad...'},
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        debugPrint('✅ WhatsApp opened');
      } else {
        if (mounted) {
          ErrorHandler.showError(
            context,
            'WhatsApp is not installed on your device.',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error launching WhatsApp: $e');
    }
  }

  Future<void> _loadMarkets() async {
    if (!mounted) return;

    final result = await sl<GetMarkets>()();

    if (!mounted) return;

    result.fold(
      (failure) {
        debugPrint('❌ Failed to load markets: ${failure.message}');
        setState(() {
          _markets = [];
          _marketsLoaded = true;
        });
      },
      (markets) {
        final activeMarkets = markets.where((m) => m.isActive).toList();
        debugPrint(
          '📊 Total markets: ${markets.length}, Active: ${activeMarkets.length}',
        );

        setState(() {
          _markets = activeMarkets;
          _marketsLoaded = true;
        });

        _tryPreSelectMarket();
      },
    );
  }

  void _tryPreSelectMarket() {
    if (_marketsLoaded &&
        _profileLoaded &&
        _currentMarketId != null &&
        _selectedMarket == null &&
        _markets.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedMarket = _markets.firstWhere(
              (m) => m.id == _currentMarketId,
              orElse: () => _markets.first,
            );
          });
        }
      });
    }
  }

  void _showConfirmationDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.warning_2,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _handleUpdateProfile() {
    if (_email.isNotEmpty) {
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(_email)) {
        toastification.show(
          context: context,
          title: const Text('Invalid Email'),
          description: const Text('Please enter a valid email address'),
          type: ToastificationType.warning,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 3),
        );
        return;
      }
    }

    final marketId = _selectedMarket?.id ?? _currentMarketId;

    if (marketId == null) {
      toastification.show(
        context: context,
        title: const Text('Market Required'),
        description: const Text('Please select a market'),
        type: ToastificationType.warning,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    context.read<ProfileBloc>().add(
      UpdateProfileEvent(
        name: _name,
        email: _email.isEmpty ? null : _email,
        marketId: marketId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ErrorHandler.showError(context, state.message);
          } else if (state is ProfileUpdated) {
            // ✅ Update current profile
            _currentProfile = state.profile;
            _name = state.profile.name;
            _email = state.profile.email ?? '';

            toastification.show(
              context: context,
              title: const Text('Success'),
              description: const Text('Profile updated successfully!'),
              type: ToastificationType.success,
              style: ToastificationStyle.fillColored,
              autoCloseDuration: const Duration(seconds: 3),
            );
          } else if (state is AccountDeleted) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (state is ProfileImageUploaded) {
            toastification.show(
              context: context,
              title: const Text('Success'),
              description: const Text('Profile image updated!'),
              type: ToastificationType.success,
              style: ToastificationStyle.fillColored,
              autoCloseDuration: const Duration(seconds: 2),
            );
          } else if (state is ProfileLoaded) {
            // ✅ Store profile
            _currentProfile = state.profile;
            _name = state.profile.name;
            _email = state.profile.email ?? '';
            _currentMarketId = state.profile.marketId;
            _profileLoaded = true;

            setState(() {}); // ✅ Trigger rebuild
            _tryPreSelectMarket();
          }
        },
        builder: (context, state) {
          // Show loading only on initial load
          if (_isInitializing && state is ProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ED573)),
            );
          }

          // Show error state if profile failed to load initially
          if (state is ProfileError && !_profileLoaded) {
            return _buildErrorState(context, state.message);
          }

          // ✅ Show profile content once we have the profile
          if (_currentProfile != null) {
            return Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      ProfileHeader(
                        onBackPressed: () => Navigator.pop(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            ProfileImagePicker(
                              imageUrl: _currentProfile!.profileImage,
                              onImagePicked: (base64Image) {
                                context.read<ProfileBloc>().add(
                                  UploadProfileImageEvent(base64Image),
                                );
                              },
                            ),
                            // ✅ Pass the actual profile object, not null
                            ProfileForm(
                              profile: _currentProfile!,
                              selectedMarket: _selectedMarket,
                              onNameChanged: (name) => _name = name,
                              onEmailChanged: (email) => _email = email,
                              onMarketTap: () {
                                setState(() => _isMarketDropdownOpen = true);
                              },
                              onUpdatePressed: _handleUpdateProfile,
                              isUpdating: state is ProfileLoading,
                            ),
                            WarningSection(
                              onWhatsAppPressed: _openWhatsApp,
                              onDeletePressed: () {
                                _showConfirmationDialog(
                                  'Delete Account',
                                  'Are you sure? This action cannot be undone and all your data will be permanently lost.',
                                  () {
                                    context.read<ProfileBloc>().add(
                                      DeleteAccountEvent(),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                MarketDropdown(
                  isOpen: _isMarketDropdownOpen,
                  selectedMarket: _selectedMarket,
                  markets: _markets,
                  onMarketSelected: (market) {
                    setState(() {
                      _selectedMarket = market;
                      _currentMarketId = market.id;
                      _isMarketDropdownOpen = false;
                    });
                  },
                  onClose: () => setState(() => _isMarketDropdownOpen = false),
                ),
              ],
            );
          }

          // Fallback loading
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final friendlyMessage = ErrorHandler.parseError(message);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(_getErrorIcon(message), size: 48, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text(
              _getErrorTitle(message),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              friendlyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _profileLoaded = false;
                  _isInitializing = true;
                  _currentProfile = null;
                });
                context.read<ProfileBloc>().add(LoadProfileEvent());
              },
              icon: const Icon(Iconsax.refresh, size: 18),
              label: const Text('Try Again'),
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
        ),
      ),
    );
  }

  IconData _getErrorIcon(String message) {
    final errorStr = message.toLowerCase();
    if (errorStr.contains('internet') || errorStr.contains('network')) {
      return Iconsax.wifi_square;
    }
    if (errorStr.contains('timeout')) return Iconsax.timer_1;
    if (errorStr.contains('login') || errorStr.contains('session')) {
      return Iconsax.lock;
    }
    return Iconsax.warning_2;
  }

  String _getErrorTitle(String message) {
    final errorStr = message.toLowerCase();
    if (errorStr.contains('internet') || errorStr.contains('network')) {
      return 'No Connection';
    }
    if (errorStr.contains('timeout')) return 'Request Timed Out';
    if (errorStr.contains('login') || errorStr.contains('session')) {
      return 'Login Required';
    }
    return 'Unable to Load Profile';
  }
}
