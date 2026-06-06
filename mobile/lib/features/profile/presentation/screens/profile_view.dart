import 'package:flutter/material.dart';

import 'package:mobile/features/profile/presentation/widgets/market_dropdown.dart';

import 'package:mobile/features/profile/presentation/widgets/profile_form.dart';
import 'package:mobile/features/profile/presentation/widgets/profile_header.dart';
import 'package:mobile/features/profile/presentation/widgets/profile_image_picker.dart';
import 'package:mobile/features/profile/presentation/widgets/warning_section.dart';
import 'package:mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  void _showAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
              style: TextButton.styleFrom(
                foregroundColor: title == 'Logout' ? null : Colors.red,
              ),
              child: Text(title == 'Logout' ? 'Logout' : 'Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
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
                            imagePath: provider.profile.profileImage,
                            onImagePicked: provider.updateProfileImage,
                          ),
                          ProfileForm(
                            profile: provider.profile,
                            onNameChanged: provider.updateName,
                            onMarketTap: provider.toggleMarketDropdown,
                            onUpdatePressed: () async {
                              final success = await provider.updateProfile();
                              if (success) {
                                _showAlert(
                                  context,
                                  'Success',
                                  'Profile updated successfully!',
                                );
                              } else {
                                _showAlert(
                                  context,
                                  'Error',
                                  'Please fill all fields',
                                );
                              }
                            },

                            isUpdating: provider.isUpdating,
                          ),
                          WarningSection(
                            onWhatsAppPressed: () {
                              provider.contactWhatsApp();
                              _showAlert(
                                context,
                                'WhatsApp',
                                'Opening WhatsApp...',
                              );
                            },
                            onDeletePressed: () {
                              _showConfirmationDialog(
                                context,
                                'Account Deletion',
                                'This action cannot be undone. All your data will be permanently lost.',
                                () async {
                                  await provider.deleteAccount();
                                  _showAlert(
                                    context,
                                    'Account Deleted',
                                    'Your account has been deleted.',
                                  );
                                  Navigator.pushReplacementNamed(context, '/');
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
                isOpen: provider.isMarketDropdownOpen,
                selectedMarket: provider.profile.market,
                markets: provider.markets,
                onMarketSelected: (market) {
                  // provider.updateMarket(market);
                  provider.closeMarketDropdown();
                },
                onClose: provider.closeMarketDropdown,
              ),
            ],
          );
        },
      ),
    );
  }
}
