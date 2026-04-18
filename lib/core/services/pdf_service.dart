import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/debt.dart';

class PdfService {
  static Future<void> generateAndShareDebtReport(List<Debt> debts) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final activeDebts = debts.where((d) => !d.isPaid).toList();
    final paidDebts = debts.where((d) => d.isPaid).toList();

    final totalActive = activeDebts.fold(0.0, (sum, item) => sum + item.amount);
    final totalPaid = paidDebts.fold(0.0, (sum, item) => sum + item.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'LAPORAN LUNASIN',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                dateFormat.format(now),
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        footer: (pw.Context context) => pw.Footer(
          margin: const pw.EdgeInsets.only(top: 32),
          trailing: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Belum Lunas',
                  currencyFormat.format(totalActive),
                  PdfColors.red900,
                ),
                _buildSummaryItem(
                  'Sudah Lunas',
                  currencyFormat.format(totalPaid),
                  PdfColors.green900,
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              'Daftar Pinjaman Aktif',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildDebtTable(activeDebts, currencyFormat, dateFormat),
            if (paidDebts.isNotEmpty) ...[
              pw.SizedBox(height: 30),
              pw.Text(
                'Riwayat Pelunasan',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildDebtTable(
                paidDebts,
                currencyFormat,
                dateFormat,
                isPaid: true,
              ),
            ],
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      "${output.path}/Laporan_Lunasin_${now.millisecondsSinceEpoch}.pdf",
    );
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Laporan Catatan Pinjaman Lunasin');
  }

  static pw.Widget _buildSummaryItem(
    String title,
    String amount,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 10, color: color)),
          pw.SizedBox(height: 4),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDebtTable(
    List<Debt> debts,
    NumberFormat currencyFormat,
    DateFormat dateFormat, {
    bool isPaid = false,
  }) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      headers: [
        'Nama',
        'Jumlah',
        'Tanggal',
        isPaid ? 'Tgl Lunas' : 'Jatuh Tempo',
      ],
      data: debts.map((d) {
        return [
          d.name,
          currencyFormat.format(d.amount),
          dateFormat.format(d.date),
          isPaid
              ? (d.paidDate != null ? dateFormat.format(d.paidDate!) : '-')
              : (d.dueDate != null ? dateFormat.format(d.dueDate!) : '-'),
        ];
      }).toList(),
    );
  }
}
