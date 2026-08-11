// lib/features/admin/presentation/screens/create_banner_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_event.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_state.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_discount_section.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_flash_sale_section.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_form_fields.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_preview_card.dart';

import 'package:mobile/features/product/data/models/banner_form_data.dart';
import 'package:toastification/toastification.dart';

class CreateBannerScreen extends StatefulWidget {
  const CreateBannerScreen({super.key});

  @override
  State<CreateBannerScreen> createState() => _CreateBannerScreenState();
}

class _CreateBannerScreenState extends State<CreateBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  // ✅ FIXED: Use named constructor
  final _formData = BannerFormData.create();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Banner',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AdminBannerBloc, AdminBannerState>(
        listener: (context, state) {
          if (state is AdminBannerOperationSuccess) {
            setState(() => _isLoading = false);
            _showSuccessToast(state.message);
            Navigator.pop(context);
          } else if (state is AdminBannerError) {
            setState(() => _isLoading = false);
            _showErrorToast(state.message);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview Card
                  BannerPreviewCard(
                    formData: _formData,
                    selectedImage: _selectedImage,
                  ),
                  const SizedBox(height: 20),

                  // Form Fields
                  BannerFormFields(
                    formData: _formData,
                    selectedImage: _selectedImage,
                    isUploading: _isUploading,
                    onImageSelected: (file) =>
                        setState(() => _selectedImage = file),
                    onImageRemoved: () => setState(() {
                      _selectedImage = null;
                      _formData.uploadedImageUrl = null;
                    }),
                    onImageUploaded: (url) {
                      setState(() {
                        _formData.uploadedImageUrl = url;
                        _isUploading = false;
                      });
                    },
                    onUploadStarted: () => setState(() => _isUploading = true),
                    onFormChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 24),

                  // Create Button
                  _buildCreateButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading || _isUploading ? null : _createBanner,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2ED573),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading || _isUploading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Create Banner',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  void _createBanner() {
    // ✅ Use built-in validation
    final error = _formData.validate();
    if (error != null) {
      _showErrorToast(error);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    context.read<AdminBannerBloc>().add(
      CreateBannerEvent(bannerData: _formData.toJson()),
    );
  }

  void _showSuccessToast(String message) {
    toastification.show(
      context: context,
      title: Text(message),
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _showErrorToast(String message) {
    toastification.show(
      context: context,
      title: Text(message),
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}
