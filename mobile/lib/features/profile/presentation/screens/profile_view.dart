import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/profile/domain/entities/market.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfileEvent());
    _loadMarkets();
  }

  Future<void> _loadMarkets() async {
    print('🔄 Loading markets...');
    final result = await sl<GetMarkets>()();
    result.fold(
      (failure) {
        print('❌ Failed to load markets: ${failure.message}');
        setState(() => _markets = []);
      },
      (markets) {
        print('✅ Markets loaded: ${markets.length}');
        print('📊 Markets: ${markets.map((m) => m.name).join(', ')}');
        setState(() => _markets = markets);
      },
    );
  }

  void _showConfirmationDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
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
          }
        },
        builder: (context, state) {
          // Don't show loading for ProfileUpdated state
          if (state is ProfileLoading ||
              (state is ProfileUpdated && state is! ProfileLoaded)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileLoaded || state is ProfileUpdated) {
            // Get profile from either state
            final profile = state is ProfileLoaded
                ? state.profile
                : (state as ProfileUpdated).profile;

            if (_name.isEmpty) _name = profile.name;

            return Stack(
              children: [
                Column(
                  children: [
                    ProfileHeader(onBackPressed: () => Navigator.pop(context)),
                    Expanded(
                      child: SingleChildScrollView(
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
                              onMarketTap: () {
                                setState(() => _isMarketDropdownOpen = true);
                              },
                              onUpdatePressed: () {
                                context.read<ProfileBloc>().add(
                                  UpdateProfileEvent(
                                    name: _name,
                                    email: profile.email,
                                    marketId: _selectedMarket?.id,
                                  ),
                                );
                              },
                              isUpdating: state is ProfileLoading,
                            ),
                            WarningSection(
                              onWhatsAppPressed: () {
                                // Open WhatsApp
                              },
                              onDeletePressed: () {
                                _showConfirmationDialog(
                                  'Delete Account',
                                  'Are you sure? This action cannot be undone.',
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
                    ),
                  ],
                ),
                MarketDropdown(
                  isOpen: _isMarketDropdownOpen,
                  selectedMarket: _selectedMarket,
                  markets: _markets,
                  onMarketSelected: (market) {
                    setState(() {
                      _selectedMarket = market;
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
