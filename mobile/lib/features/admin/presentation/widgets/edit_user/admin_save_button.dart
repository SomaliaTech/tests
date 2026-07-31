// lib/features/admin/presentation/widgets/edit_user/admin_save_button.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AdminSaveButton extends StatelessWidget {
  final bool hasChanges;
  final bool isLoading;
  final VoidCallback? onSave;

  const AdminSaveButton({
    super.key,
    required this.hasChanges,
    required this.isLoading,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (hasChanges && !isLoading) ? onSave : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: (hasChanges && !isLoading) ? 8 : 0,
          shadowColor: (hasChanges && !isLoading)
              ? const Color(0xFF2ED573).withValues(alpha: 0.4)
              : Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: (hasChanges && !isLoading)
                ? const LinearGradient(
                    colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                  )
                : null,
            color: (!hasChanges || isLoading) ? Colors.grey : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.tick_circle,
                        size: 20,
                        color: hasChanges ? Colors.white : Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasChanges ? 'Save Changes' : 'No Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: hasChanges ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
