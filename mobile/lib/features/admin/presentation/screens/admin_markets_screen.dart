import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/core/utils/toast_helper.dart';
import 'package:mobile/features/admin/domain/entities/market_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_market/admin_market_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_market/admin_market_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_market/admin_market_state.dart';

class AdminMarketsScreen extends StatefulWidget {
  const AdminMarketsScreen({super.key});

  @override
  State<AdminMarketsScreen> createState() => _AdminMarketsScreenState();
}

class _AdminMarketsScreenState extends State<AdminMarketsScreen> {
  List<MarketEntity> _markets = [];

  @override
  void initState() {
    super.initState();
    context.read<AdminMarketBloc>().add(FetchAllMarketsEvent());
  }

  void _showAddMarketDialog({MarketEntity? market}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddEditMarketDialog(
        market: market,
        onSubmit: (data) {
          if (market != null) {
            context.read<AdminMarketBloc>().add(
              UpdateMarketEvent(market.id, data),
            );
          } else {
            context.read<AdminMarketBloc>().add(CreateMarketEvent(data));
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(MarketEntity market) {
    final hasUsers = market.userCount != null && market.userCount! > 0;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.warning_2, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Market',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${market.name}"?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
            if (hasUsers) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.info_circle,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This market has ${market.userCount} user(s) associated with it. You cannot delete a market that has active users.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!hasUsers)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<AdminMarketBloc>().add(
                  DeleteMarketEvent(market.id),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Understood',
                style: TextStyle(
                  color: Color(0xFF2ED573),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Markets',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AdminMarketBloc, AdminMarketState>(
        listener: (context, state) {
          if (state is AdminMarketOperationSuccess) {
            ToastHelper.showSuccess(context, state.message);
          } else if (state is AdminMarketsError) {
            if (_markets.isEmpty) {
              ToastHelper.showError(context, state.message);
            }
          }
        },
        builder: (context, state) {
          if (state is AdminMarketsLoading && _markets.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (state is AdminMarketsLoaded) {
            _markets = state.markets;
          }

          if (_markets.isEmpty && state is! AdminMarketsLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.buildings, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No markets yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first market to get started',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            );
          }

          if (state is AdminMarketsError && _markets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.warning_2, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      state.message,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      context.read<AdminMarketBloc>().add(
                        FetchAllMarketsEvent(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _markets.length,
            itemBuilder: (context, index) {
              final market = _markets[index];
              return _buildMarketCard(market);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMarketDialog(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: const Text(
          'Add Market',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMarketCard(MarketEntity market) {
    final hasUsers = market.userCount != null && market.userCount! > 0;
    final hasMinOrder =
        market.freeDeliveryMinQuantity != null &&
        market.freeDeliveryMinQuantity! > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 1. Header: Market Name & Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: market.isActive
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Iconsax.buildings,
                  color: market.isActive ? AppTheme.primaryColor : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  market.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: market.isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  market.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    color: market.isActive ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ✅ 2. Delivery Info Grid (Simple & Clean)
          Row(
            children: [
              // Delivery Price
              Expanded(
                child: _buildInfoChip(
                  icon: Iconsax.money,
                  label: 'Delivery Price',
                  value: '\$${market.deliveryPrice.toStringAsFixed(2)}',
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              // Delivery Time
              Expanded(
                child: _buildInfoChip(
                  icon: Iconsax.clock,
                  label: 'Est. Time',
                  value: '${market.deliveryEstimationMinutes} min',
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ✅ 3. Footer: Min Order (if exists), Users & Actions
          Row(
            children: [
              if (hasMinOrder)
                Expanded(
                  child: _buildInfoChip(
                    icon: Iconsax.gift,
                    label: 'Free Delivery',
                    value: 'Min ${market.freeDeliveryMinQuantity} items',
                    color: Colors.blue,
                  ),
                )
              else
                const Spacer(),

              if (hasUsers) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.people,
                        size: 14,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${market.userCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Actions Menu
              PopupMenuButton<String>(
                icon: const Icon(Iconsax.more, color: Colors.grey),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showAddMarketDialog(market: market);
                      break;
                    case 'toggle_status':
                      context.read<AdminMarketBloc>().add(
                        UpdateMarketEvent(market.id, {
                          'isActive': !market.isActive,
                        }),
                      );
                      break;
                    case 'delete':
                      _showDeleteConfirmation(market);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Iconsax.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          market.isActive
                              ? Iconsax.close_circle
                              : Iconsax.tick_circle,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(market.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: !hasUsers,
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.trash,
                          size: 18,
                          color: hasUsers ? Colors.grey : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: hasUsers ? Colors.grey : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Helper Widget for Clean Info Chips
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Add/Edit Market Dialog
// ==========================================

class _AddEditMarketDialog extends StatefulWidget {
  final MarketEntity? market;
  final void Function(Map<String, dynamic>) onSubmit;

  const _AddEditMarketDialog({this.market, required this.onSubmit});

  @override
  State<_AddEditMarketDialog> createState() => _AddEditMarketDialogState();
}

class _AddEditMarketDialogState extends State<_AddEditMarketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _cityController = TextEditingController();

  // ✅ NEW CONTROLLERS
  final _deliveryPriceController = TextEditingController();
  final _freeDeliveryMinQuantityController = TextEditingController();
  final _deliveryEstimationController = TextEditingController(text: '90');

  bool _isSubmitting = false;

  bool get isEditing => widget.market != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.market!.name;
      _slugController.text = widget.market!.slug;
      _cityController.text = widget.market!.city ?? '';
      _deliveryPriceController.text = widget.market!.deliveryPrice.toString();
      _freeDeliveryMinQuantityController.text =
          widget.market!.freeDeliveryMinQuantity?.toString() ?? '';
      _deliveryEstimationController.text = widget
          .market!
          .deliveryEstimationMinutes
          .toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _cityController.dispose();
    _deliveryPriceController.dispose();
    _freeDeliveryMinQuantityController.dispose();
    _deliveryEstimationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final data = {
      'name': _nameController.text.trim(),
      'slug': _slugController.text.trim(),
      'city': _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      'deliveryPrice': double.parse(_deliveryPriceController.text),
      'freeDeliveryMinQuantity':
          _freeDeliveryMinQuantityController.text.trim().isEmpty
          ? null
          : int.parse(_freeDeliveryMinQuantityController.text),
      'deliveryEstimationMinutes': int.parse(
        _deliveryEstimationController.text,
      ),
    };

    widget.onSubmit(data);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Iconsax.edit : Iconsax.add_circle,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Market' : 'Add Market',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Basic Info
                  _buildSectionTitle('Basic Information'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Market Name',
                    hint: 'e.g., Hodon Market',
                    icon: Iconsax.buildings,
                    enabled: !_isSubmitting,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Market name is required';
                      return null;
                    },
                    onChanged: (value) {
                      if (!isEditing) {
                        setState(() {
                          _slugController.text = value.toLowerCase().replaceAll(
                            RegExp(r'[^a-z0-9]+'),
                            '-',
                          );
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _slugController,
                    label: 'Slug',
                    hint: 'market-slug',
                    icon: Iconsax.link_21,
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 16),

                  // ✅ Delivery Info
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _deliveryPriceController,
                    label: 'Delivery Price (\$) *',
                    hint: 'e.g., 10.00',
                    icon: Iconsax.money,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: !_isSubmitting,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Delivery price is required';
                      if (double.tryParse(value) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _freeDeliveryMinQuantityController,
                          label: 'Free Delivery Items',
                          hint: 'Optional',
                          icon: Iconsax.gift,
                          keyboardType: TextInputType.number,
                          enabled: !_isSubmitting,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _deliveryEstimationController,
                          label: 'Est. Time (mins) *',
                          hint: 'Default: 90',
                          icon: Iconsax.clock,
                          keyboardType: TextInputType.number,
                          enabled: !_isSubmitting,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Required';
                            if (int.tryParse(value) == null)
                              return 'Invalid number';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context),
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
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isEditing ? 'Update Market' : 'Create Market',
                                  style: const TextStyle(
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
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            validator: validator,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
