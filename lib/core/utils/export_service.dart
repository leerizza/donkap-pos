import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../features/transaction/domain/entities/transaction.dart';

class ExportService {
  static final _rupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');
  static final _fileDateFmt = DateFormat('yyyyMMdd_HHmm');

  Future<void> exportExcel(
      List<Transaction> transactions, String periodLabel) async {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan'];
    excel.delete('Sheet1');

    // Title
    sheet.appendRow([TextCellValue('LAPORAN PENJUALAN - $periodLabel')]);
    sheet.appendRow([
      TextCellValue(
          'Diekspor: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}')
    ]);
    sheet.appendRow([TextCellValue('')]);

    // Header
    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Invoice'),
      TextCellValue('Tanggal'),
      TextCellValue('Pembayaran'),
      TextCellValue('Item'),
      TextCellValue('Total (Rp)'),
    ]);

    // Data rows
    for (var i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      final totalItems =
          tx.items.fold<int>(0, (s, item) => s + item.quantity);
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(tx.invoiceNumber),
        TextCellValue(_dateFmt.format(tx.createdAt)),
        TextCellValue(
            tx.paymentMethod == PaymentMethod.cash ? 'Tunai' : 'QRIS'),
        IntCellValue(totalItems),
        DoubleCellValue(tx.totalAmount),
      ]);
    }

    // Summary
    sheet.appendRow([TextCellValue('')]);
    final totalRevenue =
        transactions.fold<double>(0, (s, t) => s + t.totalAmount);
    final totalItems = transactions.fold<int>(
        0, (s, t) => s + t.items.fold<int>(0, (si, i) => si + i.quantity));
    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('TOTAL'),
      IntCellValue(totalItems),
      DoubleCellValue(totalRevenue),
    ]);

    final bytes = excel.save();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final dateStr = _fileDateFmt.format(DateTime.now());
    final file = File('${dir.path}/laporan_$dateStr.xlsx');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [
        XFile(file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      ],
      subject: 'Laporan Penjualan $periodLabel',
    );
  }

  Future<void> exportPdf(
      List<Transaction> transactions, String periodLabel) async {
    final pdf = pw.Document();

    final totalRevenue =
        transactions.fold<double>(0, (s, t) => s + t.totalAmount);
    final totalTx = transactions.length;
    final totalItems = transactions.fold<int>(
        0, (s, t) => s + t.items.fold<int>(0, (si, i) => si + i.quantity));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Text('LAPORAN PENJUALAN',
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text(periodLabel,
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
          pw.Text(
              'Diekspor: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 16),

          // Summary row
          pw.Row(children: [
            _summaryBox('Total Pendapatan', _rupiah.format(totalRevenue)),
            pw.SizedBox(width: 12),
            _summaryBox('Transaksi', '$totalTx'),
            pw.SizedBox(width: 12),
            _summaryBox('Item Terjual', '$totalItems'),
          ]),
          pw.SizedBox(height: 20),

          // Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FixedColumnWidth(80),
              2: const pw.FixedColumnWidth(90),
              3: const pw.FixedColumnWidth(55),
              4: const pw.FixedColumnWidth(35),
              5: const pw.FlexColumnWidth(),
            },
            children: [
              // Table header
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _th('No'),
                  _th('Invoice'),
                  _th('Tanggal'),
                  _th('Bayar'),
                  _th('Item'),
                  _th('Total'),
                ],
              ),
              // Data rows
              ...transactions.asMap().entries.map((entry) {
                final i = entry.key;
                final tx = entry.value;
                final itemCount =
                    tx.items.fold<int>(0, (s, it) => s + it.quantity);
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: i.isEven ? PdfColors.white : PdfColors.grey50),
                  children: [
                    _td('${i + 1}'),
                    _td(tx.invoiceNumber),
                    _td(_dateFmt.format(tx.createdAt)),
                    _td(tx.paymentMethod == PaymentMethod.cash
                        ? 'Tunai'
                        : 'QRIS'),
                    _td('$itemCount'),
                    _td(_rupiah.format(tx.totalAmount), alignRight: true),
                  ],
                );
              }),
              // Total row
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _th(''),
                  _th(''),
                  _th(''),
                  _th('TOTAL'),
                  _th('$totalItems'),
                  _th(_rupiah.format(totalRevenue), alignRight: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final dateStr = _fileDateFmt.format(DateTime.now());
    final file = File('${dir.path}/laporan_$dateStr.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Laporan Penjualan $periodLabel',
    );
  }

  pw.Widget _summaryBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  pw.Widget _th(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _td(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }
}
