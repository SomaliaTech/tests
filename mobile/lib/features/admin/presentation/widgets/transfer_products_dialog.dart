// lib/features/admin/presentation/widgets/transfer_products_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/core/utils/toast_helper.dart';
import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_category/admin_category_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_category/admin_category_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_category/admin_category_state.dart';

class TransferProductsDialog extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const TransferProductsDialog({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<TransferProductsDialog> createState() => _TransferProductsDialogState();
}

class _TransferProductsDialogState extends State<TransferProductsDialog> {
  String? _selectedCategoryId;
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    // Fetch categories for transfer dropdown
    context.read<AdminCategoryBloc>().add(FetchCategoriesForTransferEvent());
  }

  void _handleTransfer() {
    if (_selectedCategoryId == null) {
      ToastHelper.showError(context, 'Please select a target category');
      return;
    }

    if (_selectedCategoryId == widget.categoryId) {
      ToastHelper.showError(context, 'Cannot transfer to the same category');
      return;
    }

    setState(() => _isTransferring = true);

    context.read<AdminCategoryBloc>().add(
      DeleteCategoryWithTransferEvent(
        categoryId: widget.categoryId,
        targetCategoryId: _selectedCategoryId!,
      ),
    );
  }

  void _handleCancel() {
    // ✅ Dispatch cancel event to restore the state
    context.read<AdminCategoryBloc>().add(CancelDeleteEvent());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // ✅ Handle back button press
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<AdminCategoryBloc>().add(CancelDeleteEvent());
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.warning_2,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cannot Delete Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                '"${widget.categoryName}" has subcategories or products. Transfer them to another category before deleting.',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector
              const Text(
                'Transfer to:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              BlocBuilder<AdminCategoryBloc, AdminCategoryState>(
                buildWhen: (previous, current) =>
                    current is AdminCategoriesForTransfer ||
                    current is AdminCategoriesLoading,
                builder: (context, state) {
                  if (state is AdminCategoriesLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }

                  if (state is AdminCategoriesForTransfer) {
                    // Filter out the category being deleted
                    final availableCategories = state.categories
                        .where((c) => c.id != widget.categoryId)
                        .toList();

                    if (availableCategories.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Iconsax.info_circle,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No other categories available for transfer',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCategoryId,
                          hint: const Text(
                            'Select target category',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          icon: const Icon(Iconsax.arrow_down_1, size: 20),
                          items: availableCategories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.id,
                              child: Text(
                                category.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategoryId = value);
                          },
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isTransferring ? null : _handleCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isTransferring || _selectedCategoryId == null
                          ? null
                          : _handleTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isTransferring
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Transfer & Delete',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
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
}
