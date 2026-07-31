// lib/features/profile/presentation/screens/complete_profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String token;
  const CompleteProfileScreen({super.key, required this.token});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

  String? _profileImageUrl;
  bool _uploading = false;

  // Markets data
  List<Map<String, dynamic>> _markets = [];
  String? _selectedMarketId;
  bool _loadingMarkets = false;

  @override
  void initState() {
    super.initState();
    _fetchMarkets();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
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

        // Handle both array and paginated response
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

          // Auto-select first market if only one available
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
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Error'),
          description: Text('Failed to load markets: $e'),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
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

    context.read<AuthBloc>().add(
      CompleteProfileEvent(
        name: nameController.text.trim(),
        marketId: _selectedMarketId!,
        profileImageUrl: _profileImageUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
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
            // Navigate to home and clear the navigation stack
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          } else if (state is AuthError) {
            if (!mounted) return;
            toastification.show(
              context: context,
              title: const Text('Error'),
              description: Text(state.message),
              type: ToastificationType.error,
              autoCloseDuration: const Duration(seconds: 4),
            );
            setState(() => _uploading = false);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Profile Image Section
                _buildProfileImageSection(),

                const SizedBox(height: 32),

                // Full Name Field
                TextFormField(
                  controller: nameController,
                  decoration: _inputDecoration(
                    'Full Name *',
                    Icons.person,
                    'Enter your full name',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Name is required';
                    }
                    if (v.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 20),

                // Market Selection Section
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
                          : const Text(
                              'Complete Profile',
                              style: TextStyle(
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
                      color: Colors.black.withOpacity(0.5),
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
            value:
                _selectedMarketId, // ✅ Fixed: using 'value' instead of 'initialValue'
            decoration: _inputDecoration(
              'Market *',
              Icons.location_city,
              'Select your market',
            ),
            items: _markets.map<DropdownMenuItem<String>>((market) {
              final marketName = market['name'] ?? 'Unknown Market';
              final city = market['city'];
              final userCount =
                  market['userCount'] ?? market['user_count'] ?? 0;

              return DropdownMenuItem<String>(
                value: market['id'] as String,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marketName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedMarketId = value);
            },
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Please select a market';
              }
              return null;
            },
            dropdownColor: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            isExpanded: true,
            style: const TextStyle(color: Colors.black87, fontSize: 15),
          ),
        if (_selectedMarketId != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2ED573).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2ED573).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF2ED573),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Market wuxuu noqon doonaa goobta laguugu keeni doono alaabtaada. Waxaad ka beddeli kartaa Settings-ka haddii aad rabto',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
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
