import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class NotesCard extends StatelessWidget {
  final String notes;

  const NotesCard({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.message, size: 20, color: Color(0xFF666666)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notes,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
