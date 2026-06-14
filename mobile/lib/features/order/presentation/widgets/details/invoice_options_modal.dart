import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/order/domain/entities/order_details.dart';
import 'package:mobile/features/order/presentation/services/pdf_invoice_service.dart';

import 'package:toastification/toastification.dart';

class InvoiceOptionsModal extends StatelessWidget {
  final OrderDetails order;

  const InvoiceOptionsModal({super.key, required this.order});

  Future<void> _handleShare(
    BuildContext context,
    PdfInvoiceService service,
  ) async {
    Navigator.pop(context);
    try {
      await service.shareInvoice(order);
      toastification.show(
        title: const Text('Success'),
        description: const Text('Invoice shared successfully'),
        type: ToastificationType.success,
      );
    } catch (e) {
      toastification.show(
        title: const Text('Error'),
        description: Text('Failed to share invoice: $e'),
        type: ToastificationType.error,
      );
    }
  }

  Future<void> _handleDownload(
    BuildContext context,
    PdfInvoiceService service,
  ) async {
    Navigator.pop(context);
    try {
      await service.downloadAndOpen(order);
      toastification.show(
        title: const Text('Success'),
        description: const Text('Invoice downloaded successfully'),
        type: ToastificationType.success,
      );
    } catch (e) {
      toastification.show(
        title: const Text('Error'),
        description: Text('Failed to download invoice: $e'),
        type: ToastificationType.error,
      );
    }
  }

  Future<void> _handlePrint(
    BuildContext context,
    PdfInvoiceService service,
  ) async {
    Navigator.pop(context);
    try {
      await service.printInvoice(order);
    } catch (e) {
      toastification.show(
        title: const Text('Error'),
        description: Text('Failed to print invoice: $e'),
        type: ToastificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = PdfInvoiceService();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Invoice Options',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildOption(
            context,
            icon: Iconsax.share,
            title: 'Share Invoice',
            subtitle: 'Share via WhatsApp, Email, etc.',
            color: const Color(0xFF2ED573),
            onTap: () => _handleShare(context, service),
          ),
          _buildOption(
            context,
            icon: Iconsax.document_download,
            title: 'Download Invoice',
            subtitle: 'Save to device',
            color: const Color(0xFF2196F3),
            onTap: () => _handleDownload(context, service),
          ),
          _buildOption(
            context,
            icon: Iconsax.printer,
            title: 'Print Invoice',
            subtitle: 'Print directly',
            color: const Color(0xFFFF9800),
            onTap: () => _handlePrint(context, service),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
