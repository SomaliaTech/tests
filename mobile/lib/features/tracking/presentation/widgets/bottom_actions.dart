import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class BottomActions extends StatelessWidget {
  final VoidCallback onContactSupport;
  final VoidCallback onTrackOnMap;

  const BottomActions({
    super.key,
    required this.onContactSupport,
    required this.onTrackOnMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Contact Support Button
            Expanded(
              child: GestureDetector(
                onTap: onContactSupport,
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2ED573)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Iconsax.message, size: 20, color: Color(0xFF2ED573)),
                      SizedBox(width: 8),
                      Text(
                        'Contact Support',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2ED573),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Track on Map Button
          ],
        ),
      ),
    );
  }
}
