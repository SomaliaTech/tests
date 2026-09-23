import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/admin/domain/entities/promo_code_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_event.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_state.dart';

class AdminPromoCodeDetailsScreen extends StatefulWidget {
  final PromoCodeEntity promoCode;
  const AdminPromoCodeDetailsScreen({super.key, required this.promoCode});

  @override
  State<AdminPromoCodeDetailsScreen> createState() =>
      _AdminPromoCodeDetailsScreenState();
}

class _AdminPromoCodeDetailsScreenState
    extends State<AdminPromoCodeDetailsScreen> {
  late TextEditingController _discountController;
  late TextEditingController _maxUsesController;
  late TextEditingController _maxUsesPerUserController;
  late TextEditingController _minOrderController;
  late TextEditingController _maxDiscountController;

  late String _discountType;
  bool _isActive = false;
  DateTime? _expiresAt;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.promoCode;
    _discountController = TextEditingController(
      text: p.discountValue?.toString() ?? '0',
    );
    _maxUsesController = TextEditingController(
      text: p.maxUses?.toString() ?? '',
    );
    _maxUsesPerUserController = TextEditingController(
      text: p.maxUsesPerUser?.toString() ?? '1',
    );
    _minOrderController = TextEditingController(
      text: p.minOrderAmount?.toString() ?? '',
    );
    _maxDiscountController = TextEditingController(
      text: p.maxDiscountAmount?.toString() ?? '',
    );

    _discountType = p.discountType ?? 'PERCENTAGE';
    _isActive = p.isActive ?? false;
    _expiresAt = p.expiresAt;
  }

  @override
  void dispose() {
    _discountController.dispose();
    _maxUsesController.dispose();
    _maxUsesPerUserController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final data = <String, dynamic>{
      'discountType': _discountType,
      'discountValue': double.parse(
        _discountController.text.isEmpty ? '0' : _discountController.text,
      ),
      'isActive': _isActive,
    };

    if (_maxUsesController.text.isNotEmpty) {
      data['maxUses'] = int.parse(_maxUsesController.text);
    }
    if (_maxUsesPerUserController.text.isNotEmpty) {
      data['maxUsesPerUser'] = int.parse(_maxUsesPerUserController.text);
    }
    if (_minOrderController.text.isNotEmpty) {
      data['minOrderAmount'] = double.parse(_minOrderController.text);
    }
    if (_maxDiscountController.text.isNotEmpty) {
      data['maxDiscountAmount'] = double.parse(_maxDiscountController.text);
    }

    // ✅ Always send expiresAt (null to clear)
    data['expiresAt'] = _expiresAt?.toIso8601String();

    if (kDebugMode) {
      debugPrint('📤 [SavePromo] Sending: $data');
    }

    context.read<AffiliateBloc>().add(
      AdminUpdatePromoCodeEvent(promoCodeId: widget.promoCode.id, data: data),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Iconsax.danger, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('Delete Promo Code', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete this promo code?',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4757), Color(0xFFFF6B6B)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.discount_shape,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.promoCode.code ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.promoCode.discountType == 'PERCENTAGE'
                              ? '${widget.promoCode.discountValue}% OFF'
                              : '\$${widget.promoCode.discountValue?.toStringAsFixed(2) ?? '0'} OFF',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ This action cannot be undone. Customers will no longer be able to use this code.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deletePromoCode();
            },
            icon: const Icon(Iconsax.trash, size: 18),
            label: const Text('Delete Permanently'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deletePromoCode() {
    setState(() => _isDeleting = true);
    context.read<AffiliateBloc>().add(
      AdminDeletePromoCodeEvent(promoCodeId: widget.promoCode.id),
    );
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.promoCode;
    final affiliateName =
        p.affiliateName ?? (p.affiliateId == null ? 'System' : 'Unknown');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.arrow_left_2, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          p.code ?? 'Promo Code',
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        actions: [
          // 🗑️ DELETE BUTTON IN APP BAR
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: _isDeleting ? null : _showDeleteConfirmation,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.trash, color: Colors.red, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<AffiliateBloc, AffiliateState>(
        // ✅ Only listen for operation results
        listenWhen: (prev, curr) =>
            curr is AffiliateOperationSuccess || curr is AffiliateError,
        listener: (context, state) {
          if (state is AffiliateOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF2ED573),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            Navigator.pop(context); // Go back to the list
          } else if (state is AffiliateError) {
            setState(() => _isDeleting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AffiliateLoading;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 📊 OVERVIEW & STATS
              _buildCard(
                title: 'Overview & Stats',
                icon: Iconsax.chart_2,
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                children: [
                  _buildInfoRow('Creator', affiliateName, Iconsax.user),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Description',
                    p.description ?? 'None',
                    Iconsax.document_text,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          'Used',
                          '${p.usedCount ?? 0}',
                          Iconsax.tick_circle,
                          const Color(0xFF2ED573),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          'Revenue',
                          '\$${p.totalRevenue?.toStringAsFixed(2) ?? '0.00'}',
                          Iconsax.dollar_circle,
                          const Color(0xFF0984E3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 💰 DISCOUNT SETTINGS
              _buildCard(
                title: 'Discount Settings',
                icon: Iconsax.money_tick,
                gradient: const LinearGradient(
                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTypeChip('PERCENTAGE', '% Percentage'),
                        _buildTypeChip('FIXED', '\$ Fixed Amount'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _discountController,
                    'Discount Value',
                    _discountType == 'PERCENTAGE'
                        ? Iconsax.percentage_circle
                        : Iconsax.dollar_circle,
                    isNum: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _minOrderController,
                    'Minimum Order Amount (\$)',
                    Iconsax.shopping_bag,
                    isNum: true,
                    hint: 'e.g., 50.00',
                  ),
                  if (_discountType == 'PERCENTAGE') ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      _maxDiscountController,
                      'Maximum Discount Cap (\$)',
                      Iconsax.arrow3,
                      isNum: true,
                      hint: 'e.g., 100.00',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // ⚙️ LIMITS & EXPIRY
              _buildCard(
                title: 'Limits & Expiration',
                icon: Iconsax.setting_2,
                gradient: const LinearGradient(
                  colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                ),
                children: [
                  _buildTextField(
                    _maxUsesController,
                    'Total Max Uses',
                    Iconsax.global,
                    isNum: true,
                    hint: 'Leave blank for unlimited',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _maxUsesPerUserController,
                    'Max Uses Per User',
                    Iconsax.user_tick,
                    isNum: true,
                    hint: 'e.g., 1',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Expiration Date',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickExpiryDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Iconsax.calendar,
                            color: Color(0xFF2ED573),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _expiresAt != null
                                  ? '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                                  : 'No expiration (Tap to set)',
                              style: TextStyle(
                                color: _expiresAt != null
                                    ? const Color(0xFF1F2937)
                                    : const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_expiresAt != null)
                            GestureDetector(
                              onTap: () => setState(() => _expiresAt = null),
                              child: const Icon(
                                Iconsax.close_circle,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 🚀 STATUS
              _buildCard(
                title: 'Status',
                icon: Iconsax.shield_tick,
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Activate Code',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            _isActive
                                ? 'Customers can use this code'
                                : 'Code is hidden/inactive',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                        activeColor: const Color(0xFF2ED573),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 🚀 ACTION BUTTONS
              Row(
                children: [
                  // 🗑️ DELETE BUTTON
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _showDeleteConfirmation,
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.red,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Iconsax.trash, color: Colors.red),
                        label: Text(
                          'Delete',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // ✅ SAVE BUTTON
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _saveChanges,
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Iconsax.tick_circle),
                        label: Text(
                          _isActive ? 'Approve & Save' : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ED573),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: const Color(
                            0xFF2ED573,
                          ).withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNum = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNum
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF2ED573), size: 20),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2ED573), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _discountType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _discountType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2ED573) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
