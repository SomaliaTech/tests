import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/order_details.dart';

class PdfInvoiceService {
  Future<File> generateInvoice(OrderDetails order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildHeader(order),
          pw.SizedBox(height: 20),
          _buildOrderInfo(order),
          pw.SizedBox(height: 20),
          _buildShippingAddress(order),
          pw.SizedBox(height: 20),
          _buildItemsTable(order),
          pw.SizedBox(height: 20),
          _buildSummary(order),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    // Save PDF to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${order.orderNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> shareInvoice(OrderDetails order) async {
    final file = await generateInvoice(order);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Invoice for Order ${order.orderNumber}',
      subject: 'Your Invoice',
    );
  }

  Future<void> downloadAndOpen(OrderDetails order) async {
    final file = await generateInvoice(order);
    await OpenFile.open(file.path);
  }

  Future<void> printInvoice(OrderDetails order) async {
    final pdf = await generateInvoice(order);
    final pdfBytes = await pdf.readAsBytes();
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          'invoice_${order.orderNumber}.pdf', // Changed from 'name' to 'filename'
    );
  }

  pw.Widget _buildHeader(OrderDetails order) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Order #${order.orderNumber}',
              style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildOrderInfo(OrderDetails order) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Order Information',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoRow('Order Date:', order.formattedDate),
              _buildInfoRow('Order Status:', order.status.displayName),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoRow('Payment Method:', order.paymentMethod),
              _buildInfoRow('Payment Status:', order.paymentStatus.displayName),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildShippingAddress(OrderDetails order) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Delivery Information',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow('Recipient:', order.recipientName),
          pw.SizedBox(height: 4),
          _buildInfoRow('Phone:', order.recipientPhone),
          pw.SizedBox(height: 4),
          _buildInfoRow('Address:', order.deliveryAddress),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(OrderDetails order) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Order Items',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey300),
              bottom: pw.BorderSide(color: PdfColors.grey300),
            ),
            columnWidths: {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Product', isHeader: true),
                  _buildTableCell(
                    'Qty',
                    isHeader: true,
                    alignment: pw.Alignment.centerRight,
                  ),
                  _buildTableCell(
                    'Total',
                    isHeader: true,
                    alignment: pw.Alignment.centerRight,
                  ),
                ],
              ),
              ...order.items.map(
                (item) => pw.TableRow(
                  children: [
                    _buildTableCell(item.name),
                    _buildTableCell(
                      item.quantity.toString(),
                      alignment: pw.Alignment.centerRight,
                    ),
                    _buildTableCell(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      alignment: pw.Alignment.centerRight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummary(OrderDetails order) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Subtotal:'),
              pw.Text('\$${order.subtotal.toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Shipping Fee:'),
              pw.Text('\$${order.shippingFee.toStringAsFixed(2)}'),
            ],
          ),
          if (order.discount > 0) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Discount:'),
                pw.Text('-\$${order.discount.toStringAsFixed(2)}'),
              ],
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'Thank you for your purchase!',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'For any inquiries, please contact our support team',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 8),
        pw.Text(value, style: pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 11,
        ),
      ),
    );
  }
}
