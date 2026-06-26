import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/profile/domain/entities/market.dart';
import 'package:mobile/features/profile/domain/entities/profile.dart';
import 'package:mobile/features/profile/domain/usecases/get_markets.dart';
import 'package:toastification/toastification.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfileEvent());
    _loadMarkets();
  }

  Future<void> _loadMarkets() async {
    final result = await sl<GetMarkets>()();
    result.fold(
      (failure) {
        if (mounted)
          setState(() {
            _markets = [];
            _marketsLoaded = true;
          });
      },
      (markets) {
        if (mounted) {
          setState(() {
            _markets = markets;
            _marketsLoaded = true;
          });
          _tryPreSelectMarket();
        }
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            toastification.show(
              title: const Text('Error'),
              description: Text(state.message),
              type: ToastificationType.error,
            );
          } else if (state is ProfileUpdated) {
            toastification.show(
              title: const Text('Success'),
              description: const Text('Profile updated successfully!'),
              type: ToastificationType.success,
            );
          } else if (state is AccountDeleted) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (state is ProfileImageUploaded) {
            toastification.show(
              title: const Text('Success'),
              description: const Text('Profile image updated!'),
              type: ToastificationType.success,
            );
          } else if (state is ProfileLoaded) {
            final profile = state.profile;
            if (_name.isEmpty) _name = profile.name;
            if (_email.isEmpty) _email = profile.email ?? '';

            if (_currentMarketId == null && profile.marketId != null) {
              _currentMarketId = profile.marketId;
              _profileLoaded = true;
              _tryPreSelectMarket();
            }
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ED573)),
            );
          }

          if (state is ProfileLoaded || state is ProfileUpdated) {
            final profile = state is ProfileLoaded
                ? state.profile
                : (state as ProfileUpdated).profile;

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
                              imageUrl: profile.profileImage,
                              onImagePicked: (base64Image) {
                                context.read<ProfileBloc>().add(
                                  UploadProfileImageEvent(base64Image),
                                );
                              },
                            ),
                            ProfileForm(
                              profile: profile,
                              selectedMarket: _selectedMarket,
                              onNameChanged: (name) => _name = name,
                              onEmailChanged: (email) => _email = email,
                              onMarketTap: () {
                                setState(() => _isMarketDropdownOpen = true);
                              },
                              onUpdatePressed: () {
                                if (_email.isNotEmpty) {
                                  final emailRegex = RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  );
                                  if (!emailRegex.hasMatch(_email)) {
                                    toastification.show(
                                      title: const Text('Error'),
                                      description: const Text(
                                        'Please enter a valid email address',
                                      ),
                                      type: ToastificationType.error,
                                    );
                                    return;
                                  }
                                }

                                final marketId =
                                    _selectedMarket?.id ?? _currentMarketId;

                                if (marketId == null) {
                                  toastification.show(
                                    title: const Text('Error'),
                                    description: const Text(
                                      'Please select a market',
                                    ),
                                    type: ToastificationType.error,
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
                              },
                              isUpdating: state is ProfileLoading,
                            ),
                            WarningSection(
                              onWhatsAppPressed: () {},
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

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
