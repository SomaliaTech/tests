// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:mobile/core/utils/toast_helper.dart';
// import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_bloc.dart';
// import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_event.dart';
// import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_state.dart';

// class CreatePromoCodeScreen extends StatefulWidget {
//   const CreatePromoCodeScreen({super.key});

//   @override
//   State<CreatePromoCodeScreen> createState() => _CreatePromoCodeScreenState();
// }

// class _CreatePromoCodeScreenState extends State<CreatePromoCodeScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _codeController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _discountValueController = TextEditingController();

//   String _discountType = 'PERCENTAGE';

//   @override
//   void dispose() {
//     _codeController.dispose();
//     _descriptionController.dispose();
//     _discountValueController.dispose();
//     super.dispose();
//   }

//   void _generateRandomCode() {
//     const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
//     final random = DateTime.now().millisecondsSinceEpoch;
//     String code = '';
//     for (int i = 0; i < 6; i++) {
//       code += chars[(random + i * 7) % chars.length];
//     }
//     setState(() {
//       _codeController.text = code;
//     });
//   }

//   void _submit() {
//     if (!_formKey.currentState!.validate()) return;

//     final data = {
//       'code': _codeController.text.trim().toUpperCase(),
//       'description': _descriptionController.text.trim().isEmpty
//           ? null
//           : _descriptionController.text.trim(),
//       'discountType': _discountType,
//       'discountValue': double.parse(_discountValueController.text),

//       // ❌ MAKE SURE THIS LINE IS DELETED:
//       // 'isActive': false,
//     };

//     context.read<AffiliateBloc>().add(
//       CreateAffiliatePromoCodeEvent(data: data),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: const Color(0xFFF3F4F6),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(Iconsax.arrow_left_2, size: 20),
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Request Promo Code',
//           style: TextStyle(
//             color: Color(0xFF1F2937),
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: BlocConsumer<AffiliateBloc, AffiliateState>(
//         listener: (context, state) {
//           if (state is AffiliateOperationSuccess) {
//             ToastHelper.showSuccess(context, state.message);
//             Navigator.pop(context);
//           } else if (state is AffiliateError) {
//             ToastHelper.showError(context, state.message);
//           }
//         },
//         builder: (context, state) {
//           final isCreating = state is AffiliateLoading;

//           return Form(
//             key: _formKey,
//             child: ListView(
//               padding: const EdgeInsets.all(16),
//               children: [
//                 // ✅ Info Banner explaining the approval process
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF0984E3).withValues(alpha: 0.08),
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(
//                       color: const Color(0xFF0984E3).withValues(alpha: 0.2),
//                     ),
//                   ),
//                   child: const Row(
//                     children: [
//                       Icon(
//                         Iconsax.info_circle,
//                         color: Color(0xFF0984E3),
//                         size: 24,
//                       ),
//                       SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           'Your promo code will be reviewed and approved by an admin before it becomes active.',
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: Color(0xFF0984E3),
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Promo Code Section
//                 _buildSectionCard(
//                   title: 'Promo Code',
//                   icon: Iconsax.discount_shape,
//                   children: [
//                     _buildTextField(
//                       controller: _codeController,
//                       label: 'Code',
//                       hint: 'e.g., SUMMER25',
//                       icon: Iconsax.tag,
//                       isUppercase: true,
//                       validator: (v) {
//                         if (v == null || v.trim().isEmpty) {
//                           return 'Code is required';
//                         }
//                         if (v.trim().length < 3) return 'At least 3 characters';
//                         if (v.trim().length > 20) return 'Max 20 characters';
//                         if (!RegExp(
//                           r'^[A-Z0-9]+$',
//                         ).hasMatch(v.trim().toUpperCase())) {
//                           return 'Only letters and numbers allowed';
//                         }
//                         return null;
//                       },
//                       suffix: TextButton(
//                         onPressed: _generateRandomCode,
//                         child: const Text(
//                           'Generate',
//                           style: TextStyle(
//                             color: Color(0xFF2ED573),
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildTextField(
//                       controller: _descriptionController,
//                       label: 'Description (optional)',
//                       hint: 'e.g., Summer sale discount',
//                       icon: Iconsax.document_text,
//                       maxLines: 2,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),

//                 // Discount Section
//                 _buildSectionCard(
//                   title: 'Discount',
//                   icon: Iconsax.money_tick,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(4),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF3F4F6),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         children: [
//                           _buildTypeChip('PERCENTAGE', '% Percentage'),
//                           _buildTypeChip('FIXED', '\$ Fixed Amount'),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildTextField(
//                       controller: _discountValueController,
//                       label: 'Requested Discount',
//                       hint: _discountType == 'PERCENTAGE' ? '10' : '5.00',
//                       icon: _discountType == 'PERCENTAGE'
//                           ? Iconsax.percentage_circle
//                           : Iconsax.dollar_circle,
//                       keyboardType: const TextInputType.numberWithOptions(
//                         decimal: true,
//                       ),
//                       suffix: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         child: Text(
//                           _discountType == 'PERCENTAGE' ? '%' : '\$',
//                           style: const TextStyle(
//                             color: Color(0xFF6B7280),
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       validator: (v) {
//                         if (v == null || v.isEmpty) return 'Required';
//                         final value = double.tryParse(v);
//                         if (value == null) return 'Invalid number';
//                         if (value <= 0) return 'Must be positive';
//                         if (_discountType == 'PERCENTAGE' && value > 100) {
//                           return 'Cannot exceed 100%';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       'Note: The admin may adjust your requested discount percentage during the approval process.',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Color(0xFF9CA3AF),
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 32),

//                 // Submit Button
//                 SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton(
//                     onPressed: isCreating ? null : _submit,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.transparent,
//                       foregroundColor: Colors.white,
//                       padding: EdgeInsets.zero,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       elevation: 6,
//                       shadowColor: const Color(
//                         0xFF2ED573,
//                       ).withValues(alpha: 0.4),
//                     ),
//                     child: Ink(
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
//                         ),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Center(
//                         child: isCreating
//                             ? const SizedBox(
//                                 height: 24,
//                                 width: 24,
//                                 child: CircularProgressIndicator(
//                                   color: Colors.white,
//                                   strokeWidth: 2.5,
//                                 ),
//                               )
//                             : const Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Iconsax.send_2),
//                                   SizedBox(width: 8),
//                                   Text(
//                                     'Submit for Approval',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildTypeChip(String type, String label) {
//     final isSelected = _discountType == type;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => setState(() => _discountType = type),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           decoration: BoxDecoration(
//             color: isSelected ? const Color(0xFF2ED573) : Colors.transparent,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Center(
//             child: Text(
//               label,
//               style: TextStyle(
//                 color: isSelected ? Colors.white : const Color(0xFF6B7280),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionCard({
//     required String title,
//     required IconData icon,
//     required List<Widget> children,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF2ED573).withValues(alpha: 0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(icon, color: const Color(0xFF2ED573), size: 20),
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1F2937),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           ...children,
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//     int maxLines = 1,
//     bool isUppercase = false,
//     Widget? suffix,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//             color: Color(0xFF374151),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             color: const Color(0xFFF9FAFB),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: const Color(0xFFE5E7EB)),
//           ),
//           child: TextFormField(
//             controller: controller,
//             keyboardType: keyboardType,
//             maxLines: maxLines,
//             textCapitalization: isUppercase
//                 ? TextCapitalization.characters
//                 : TextCapitalization.none,
//             inputFormatters: isUppercase ? [UpperCaseTextFormatter()] : [],
//             style: const TextStyle(color: Color(0xFF1F2937)),
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
//               prefixIcon: Icon(icon, color: const Color(0xFF2ED573), size: 20),
//               suffixIcon: suffix,
//               border: InputBorder.none,
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 14,
//               ),
//             ),
//             validator: validator,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class UpperCaseTextFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//     TextEditingValue oldValue,
//     TextEditingValue newValue,
//   ) {
//     return TextEditingValue(
//       text: newValue.text.toUpperCase(),
//       selection: newValue.selection,
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/core/utils/toast_helper.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_event.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_state.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_bloc.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_event.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_state.dart';

class CreatePromoCodeScreen extends StatefulWidget {
  const CreatePromoCodeScreen({super.key});

  @override
  State<CreatePromoCodeScreen> createState() => _CreatePromoCodeScreenState();
}

class _CreatePromoCodeScreenState extends State<CreatePromoCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();

  String _discountType = 'PERCENTAGE';

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  void _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[(random + i * 7) % chars.length];
    }
    setState(() {
      _codeController.text = code;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'code': _codeController.text.trim().toUpperCase(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'discountType': _discountType,
      'discountValue': double.parse(_discountValueController.text),
    };

    context.read<AffiliateUserBloc>().add(CreateMyPromoCodeEvent(data: data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.arrow_left_2, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Request Promo Code',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: BlocConsumer<AffiliateUserBloc, AffiliateUserState>(
        listener: (context, state) {
          if (state is AffiliateUserOperationSuccess) {
            ToastHelper.showSuccess(context, state.message);
            Navigator.pop(context);
          } else if (state is AffiliateUserError) {
            ToastHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final isCreating = state is AffiliateLoading;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF667eea).withValues(alpha: 0.1),
                        const Color(0xFF764ba2).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF667eea).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.info_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Your promo code will be reviewed and approved by an admin before it becomes active.',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF667eea),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Promo Code Section
                _buildSectionCard(
                  title: 'Promo Code',
                  icon: Iconsax.discount_shape,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  children: [
                    _buildTextField(
                      controller: _codeController,
                      label: 'Code',
                      hint: 'e.g., SUMMER25',
                      icon: Iconsax.tag,
                      isUppercase: true,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Code is required';
                        if (v.trim().length < 3) return 'At least 3 characters';
                        if (v.trim().length > 20) return 'Max 20 characters';
                        if (!RegExp(
                          r'^[A-Z0-9]+$',
                        ).hasMatch(v.trim().toUpperCase())) {
                          return 'Only letters and numbers allowed';
                        }
                        return null;
                      },
                      suffix: TextButton(
                        onPressed: _generateRandomCode,
                        child: const Text(
                          'Generate',
                          style: TextStyle(
                            color: Color(0xFF667eea),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description (optional)',
                      hint: 'e.g., Summer sale discount',
                      icon: Iconsax.document_text,
                      maxLines: 2,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Discount Section
                _buildSectionCard(
                  title: 'Discount',
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
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _discountValueController,
                      label: 'Requested Discount',
                      hint: _discountType == 'PERCENTAGE' ? '10' : '5.00',
                      icon: _discountType == 'PERCENTAGE'
                          ? Iconsax.percentage_circle
                          : Iconsax.dollar_circle,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      suffix: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _discountType == 'PERCENTAGE' ? '%' : '\$',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final value = double.tryParse(v);
                        if (value == null) return 'Invalid number';
                        if (value <= 0) return 'Must be positive';
                        if (_discountType == 'PERCENTAGE' && value > 100) {
                          return 'Cannot exceed 100%';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.info_circle,
                            color: const Color(0xFF6B7280),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'The admin may adjust your requested discount percentage during approval.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isCreating ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF667eea,
                            ).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isCreating
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.send_2,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Submit for Approval',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _discountType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _discountType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool isUppercase = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textCapitalization: isUppercase
                ? TextCapitalization.characters
                : TextCapitalization.none,
            inputFormatters: isUppercase ? [UpperCaseTextFormatter()] : [],
            style: const TextStyle(color: Color(0xFF1F2937), fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: Icon(icon, color: const Color(0xFF667eea), size: 20),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
