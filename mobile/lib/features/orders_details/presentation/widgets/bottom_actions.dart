import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/orders_details/models/order_details_model.dart';

class BottomActions extends StatelessWidget {
  final OrderDetails order;
  final VoidCallback onReorder;
  final VoidCallback onTrack;
  final VoidCallback onInvoice;

  const BottomActions({
    super.key,
    required this.order,
    required this.onReorder,
    required this.onTrack,
    required this.onInvoice,
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
            if (order.canTrack)
              Expanded(
                child: GestureDetector(
                  onTap: onTrack,
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3742FA)),
                      color: const Color(0xFFF0F4FF),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Iconsax.location,
                          size: 20,
                          color: Color(0xFF3742FA),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Track Order',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3742FA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (order.canReorder)
              Expanded(
                child: GestureDetector(
                  onTap: onReorder,
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2ED573)),
                      color: const Color(0xFFF0FFF4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Iconsax.shopping_cart,
                          size: 20,
                          color: Color(0xFF2ED573),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Reorder',
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
            Expanded(
              child: GestureDetector(
                onTap: onInvoice,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.document, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Invoice',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
