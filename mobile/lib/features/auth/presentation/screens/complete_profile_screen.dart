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
  // ✅ REMOVED: emailController

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
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _markets = data.cast<Map<String, dynamic>>();
          _loadingMarkets = false;
        });
      } else {
        throw Exception('Failed to load markets');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMarkets = false);
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Error'),
          description: const Text('Failed to load markets'),
          type: ToastificationType.error,
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
                // Profile Image
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
                            ? const Icon(
                                Icons.camera_alt_rounded,
                                size: 40,
                                color: Colors.grey,
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to upload photo',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Full Name (Required)
                TextFormField(
                  controller: nameController,
                  decoration: _inputDecoration('Full Name *', Icons.person),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),

                // ✅ EMAIL FIELD REMOVED

                // Market Dropdown (Required)
                _loadingMarkets
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        initialValue: _selectedMarketId,
                        decoration: _inputDecoration(
                          'Market *',
                          Icons.location_city,
                        ),
                        items: _markets.map<DropdownMenuItem<String>>((market) {
                          return DropdownMenuItem<String>(
                            value: market['id'] as String,
                            child: Text(market['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedMarketId = value);
                        },
                        validator: (v) =>
                            v == null ? 'Please select a market' : null,
                      ),
                const SizedBox(height: 40),

                // Submit Button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthBloc>().add(
                                  CompleteProfileEvent(
                                    name: nameController.text.trim(),
                                    // ✅ EMAIL REMOVED - no email parameter
                                    marketId: _selectedMarketId!,
                                    profileImageUrl: _profileImageUrl,
                                  ),
                                );
                              }
                            },
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2ED573), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
