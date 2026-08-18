// lib/features/auth/presentation/screens/complete_profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ProviderInfo {
  final String prefix;
  final String name;
  final Color color;
  final IconData icon;
  const ProviderInfo({
    required this.prefix,
    required this.name,
    required this.color,
    required this.icon,
  });
}

class CompleteProfileScreen extends StatefulWidget {
  final String token;
  final User user;
  final bool isGoogleSignIn;

  const CompleteProfileScreen({
    super.key,
    required this.token,
    required this.user,
    this.isGoogleSignIn = false,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController countryCodeController = TextEditingController(
    text: '+252',
  );
  final FocusNode phoneFocusNode = FocusNode();

  String? _profileImageUrl;
  bool _uploading = false;

  List<Map<String, dynamic>> _markets = [];
  String? _selectedMarketId;
  bool _loadingMarkets = false;

  // ✅ Somali providers (only for OTP users)
  static const List<ProviderInfo> _somaliProviders = [
    ProviderInfo(
      prefix: '61',
      name: 'Hormuud',
      color: Color(0xFF2ED573),
      icon: Iconsax.mobile,
    ),
    ProviderInfo(
      prefix: '68',
      name: 'Somnet',
      color: Color(0xFF3B82F6),
      icon: Iconsax.wifi,
    ),
    ProviderInfo(
      prefix: '90',
      name: 'Golis',
      color: Color(0xFFF59E0B),
      icon: Iconsax.wallet,
    ),
    ProviderInfo(
      prefix: '63',
      name: 'Telisom',
      color: Color(0xFF8B5CF6),
      icon: Iconsax.money,
    ),
  ];

  // ✅ Common country codes (for Google users)
  static const List<String> _countryCodes = [
    '+252', // Somalia
    '+1', // USA/Canada
    '+44', // UK
    '+254', // Kenya
    '+256', // Uganda
    '+255', // Tanzania
    '+971', // UAE
    '+966', // Saudi Arabia
    '+20', // Egypt
    '+234', // Nigeria
    '+27', // South Africa
    '+49', // Germany
    '+33', // France
    '+61', // Australia
    '+46', // Sweden
    '+47', // Norway
    '+45', // Denmark
    '+31', // Netherlands
    '+32', // Belgium
    '+41', // Switzerland
    '+43', // Austria
    '+39', // Italy
    '+34', // Spain
    '+351', // Portugal
    '+353', // Ireland
    '+358', // Finland
    '+48', // Poland
    '+90', // Turkey
    '+91', // India
    '+92', // Pakistan
    '+880', // Bangladesh
    '+62', // Indonesia
    '+60', // Malaysia
    '+65', // Singapore
    '+66', // Thailand
    '+84', // Vietnam
    '+81', // Japan
    '+82', // South Korea
    '+86', // China
    '+7', // Russia
    '+55', // Brazil
    '+52', // Mexico
    '+54', // Argentina
    '+56', // Chile
    '+57', // Colombia
    '+51', // Peru
    '+58', // Venezuela
    '+972', // Israel
    '+964', // Iraq
    '+963', // Syria
    '+962', // Jordan
    '+961', // Lebanon
    '+965', // Kuwait
    '+973', // Bahrain
    '+974', // Qatar
    '+968', // Oman
    '+967', // Yemen
    '+971', // UAE
  ];

  @override
  void initState() {
    super.initState();

    if (widget.user.name != null && widget.user.name!.isNotEmpty) {
      nameController.text = widget.user.name!;
    }

    if (widget.user.profileImage != null &&
        widget.user.profileImage!.isNotEmpty) {
      _profileImageUrl = widget.user.profileImage;
    }

    // Pre-fill phone for OTP users
    if (!widget.isGoogleSignIn && widget.user.phoneNumber.isNotEmpty) {
      String phone = widget.user.phoneNumber;
      if (phone.startsWith('+252')) {
        phone = phone.substring(4);
      }
      phoneController.text = phone;
    }

    _fetchMarkets();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    countryCodeController.dispose();
    phoneFocusNode.dispose();
    super.dispose();
  }

  // ✅ Somali provider detection (only for OTP users)
  String? _detectSomaliProvider(String phone) {
    if (phone.length < 2) return null;
    for (final provider in _somaliProviders) {
      if (phone.startsWith(provider.prefix)) return provider.name;
    }
    return null;
  }

  Color? _getSomaliProviderColor(String phone) {
    if (phone.length < 2) return null;
    for (final provider in _somaliProviders) {
      if (phone.startsWith(provider.prefix)) return provider.color;
    }
    return null;
  }

  Future<void> _fetchMarkets() async {
    if (!mounted) return;
    setState(() => _loadingMarkets = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/markets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> data;
        if (responseData is Map && responseData.containsKey('items')) {
          data = responseData['items'] as List<dynamic>;
        } else if (responseData is List) {
          data = responseData;
        } else {
          throw Exception('Unexpected response format');
        }

        setState(() {
          _markets = data.cast<Map<String, dynamic>>();
          _loadingMarkets = false;
          if (_markets.length == 1) {
            _selectedMarketId = _markets[0]['id'] as String?;
          }
        });
      } else {
        throw Exception('Failed to load markets: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMarkets = false);
      toastification.show(
        context: context,
        title: const Text('Error'),
        description: Text('Failed to load markets: $e'),
        type: ToastificationType.error,
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (picked != null) {
      if (!mounted) return;
      setState(() => _uploading = true);
      try {
        final bytes = await picked.readAsBytes();
        final base64Image = base64Encode(bytes);
        if (!mounted) return;
        context.read<AuthBloc>().add(UploadProfileImageEvent(base64Image));
      } catch (e) {
        if (!mounted) return;
        setState(() => _uploading = false);
        toastification.show(
          context: context,
          title: const Text('Error'),
          description: const Text('Failed to process image'),
          type: ToastificationType.error,
        );
      }
    }
  }

  // ✅ Phone validation based on user type
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return widget.isGoogleSignIn
          ? 'Phone number is required'
          : null; // Phone not required for OTP users (they already have it)
    }

    String cleaned = value.trim().replaceAll(RegExp(r'\s+'), '');

    if (widget.isGoogleSignIn) {
      // ✅ Google users: ANY country, 6-15 digits
      if (cleaned.length < 6 || cleaned.length > 15) {
        return 'Phone number must be between 6 and 15 digits';
      }
      return null;
    } else {
      // ✅ OTP users: Somali only, 9 digits
      if (cleaned.startsWith('+252')) {
        cleaned = cleaned.substring(4);
      }
      if (cleaned.startsWith('252')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.length != 9) {
        return 'Phone number must be 9 digits';
      }
      bool isValidPrefix = _somaliProviders.any(
        (p) => cleaned.startsWith(p.prefix),
      );
      if (!isValidPrefix) {
        return 'Must start with 61, 63, 68, or 90';
      }
      return null;
    }
  }

  String _formatPhoneForApi(String phone) {
    String cleaned = phone.trim().replaceAll(RegExp(r'\s+'), '');

    if (widget.isGoogleSignIn) {
      // ✅ Google users: Use country code + phone
      final countryCode = countryCodeController.text.trim();
      return '$countryCode$cleaned';
    } else {
      // ✅ OTP users: Somali format
      if (cleaned.startsWith('+252')) {
        cleaned = cleaned.substring(4);
      }
      if (cleaned.startsWith('252')) {
        cleaned = cleaned.substring(3);
      }
      return '+252$cleaned';
    }
  }

  void _submitProfile() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMarketId == null) {
      toastification.show(
        context: context,
        title: const Text('Error'),
        description: const Text('Please select a market'),
        type: ToastificationType.error,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    String? phoneNumber;
    if (widget.isGoogleSignIn) {
      final phoneText = phoneController.text.trim();
      if (phoneText.isEmpty) {
        toastification.show(
          context: context,
          title: const Text('Error'),
          description: const Text('Phone number is required'),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 3),
        );
        return;
      }
      phoneNumber = _formatPhoneForApi(phoneText);
    }

    context.read<AuthBloc>().add(
      CompleteProfileEvent(
        name: nameController.text.trim(),
        marketId: _selectedMarketId!,
        profileImageUrl: _profileImageUrl,
        phoneNumber: phoneNumber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.isGoogleSignIn ? 'Complete Your Profile' : 'Complete Profile',
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ProfileImageUploaded) {
            if (!mounted) return;
            setState(() {
              _profileImageUrl = state.imageUrl;
              _uploading = false;
            });
            toastification.show(
              context: context,
              title: const Text('Success'),
              description: const Text('Profile image uploaded'),
              type: ToastificationType.success,
              autoCloseDuration: const Duration(seconds: 2),
            );
          } else if (state is ProfileCompleted) {
            if (!mounted) return;
            toastification.show(
              context: context,
              title: const Text('✓ Success'),
              description: const Text('Profile completed successfully!'),
              type: ToastificationType.success,
              autoCloseDuration: const Duration(seconds: 3),
            );
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          } else if (state is AuthError) {
            if (!mounted) return;
            setState(() => _uploading = false);
            toastification.show(
              context: context,
              title: const Text('Error'),
              description: Text(state.message),
              type: ToastificationType.error,
              autoCloseDuration: const Duration(seconds: 4),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileImageSection(),
                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: nameController,
                  decoration: _inputDecoration(
                    'Full Name *',
                    Icons.person,
                    'Enter your full name',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Name is required';
                    if (v.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),

                // ✅ Phone Input - DIFFERENT for Google vs OTP users
                if (widget.isGoogleSignIn) ...[
                  const SizedBox(height: 20),
                  _buildInternationalPhoneInput(), // ✅ Google: any country
                  const SizedBox(height: 8),
                  _buildPhoneHelper(),
                ] else ...[
                  const SizedBox(height: 20),
                  _buildSomaliPhoneInput(), // ✅ OTP: Somali only
                  const SizedBox(height: 8),
                  _buildSomaliProviderDetection(),
                ],

                const SizedBox(height: 20),
                _buildMarketSelection(),
                const SizedBox(height: 40),

                // Submit Button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ED573),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              widget.isGoogleSignIn
                                  ? 'Save & Continue'
                                  : 'Complete Profile',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ INTERNATIONAL PHONE INPUT (for Google users)
  Widget _buildInternationalPhoneInput() {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Country code dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: countryCodeController.text,
                items: _countryCodes.map((code) {
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    countryCodeController.text = value ?? '+252';
                  });
                },
                icon: const Icon(
                  Iconsax.arrow_down_1,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 30, color: const Color(0xFFE5E7EB)),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: phoneController,
              focusNode: phoneFocusNode,
              keyboardType: TextInputType.phone,
              maxLength: 15,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validatePhone,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText: 'Phone number',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
                counterText: '',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ SOMALI PHONE INPUT (for OTP users)
  Widget _buildSomaliPhoneInput() {
    final phone = phoneController.text;
    final providerColor = _getSomaliProviderColor(phone);

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: providerColor ?? const Color(0xFFE5E7EB),
          width: providerColor != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                providerColor?.withValues(alpha: 0.2) ??
                Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '+252',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Iconsax.arrow_down_1,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 30, color: const Color(0xFFE5E7EB)),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: phoneController,
              focusNode: phoneFocusNode,
              keyboardType: TextInputType.phone,
              maxLength: 9,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validatePhone,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: providerColor ?? const Color(0xFF1F2937),
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText: '61 XXX XXXX',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
                counterText: '',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Phone helper text (for Google users)
  Widget _buildPhoneHelper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(Iconsax.global, size: 14, color: Colors.blue.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Enter your phone number with country code',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Somali provider detection (for OTP users)
  Widget _buildSomaliProviderDetection() {
    final phone = phoneController.text;
    final detectedProvider = _detectSomaliProvider(phone);
    final providerColor = _getSomaliProviderColor(phone);

    if (phone.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(Iconsax.info_circle, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Enter a phone number to detect your provider',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      );
    }

    if (detectedProvider != null && phone.length >= 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: providerColor?.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _somaliProviders
                    .firstWhere((p) => p.name == detectedProvider)
                    .icon,
                size: 14,
                color: providerColor,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '📱 $detectedProvider detected',
                style: TextStyle(
                  fontSize: 12,
                  color: providerColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (phone.length < 9)
              Text(
                '${phone.length}/9',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(Iconsax.warning_2, size: 14, color: Colors.orange.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Please enter a valid Somali phone number',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _uploading ? null : _pickImage,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : null,
                child: _profileImageUrl == null
                    ? Icon(
                        Icons.camera_alt_rounded,
                        size: 40,
                        color: Colors.grey[400],
                      )
                    : null,
              ),
              if (_uploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              if (_profileImageUrl != null && !_uploading)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2ED573),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _profileImageUrl != null
              ? 'Tap to change photo'
              : 'Tap to upload photo',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        if (_profileImageUrl == null) ...[
          const SizedBox(height: 4),
          Text(
            'Optional',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildMarketSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Market *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 10),
        if (_loadingMarkets)
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_markets.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No markets available',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _fetchMarkets,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            decoration: _inputDecoration(
              'Market *',
              Icons.location_city,
              'Select your market',
            ),
            value: _selectedMarketId,
            items: _markets.map<DropdownMenuItem<String>>((market) {
              return DropdownMenuItem<String>(
                value: market['id'] as String,
                child: Text(
                  market['name'] ?? 'Unknown Market',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedMarketId = value),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please select a market' : null,
            dropdownColor: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            isExpanded: true,
            style: const TextStyle(color: Colors.black87, fontSize: 15),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2ED573), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
