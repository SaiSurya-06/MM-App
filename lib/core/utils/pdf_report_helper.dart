import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/transaction.dart';
import 'currency_formatter.dart';

class PdfReportHelper {
  static Future<void> generateAndShareReport({
    required List<Transaction> transactions,
    required Map<int, String> categoryNames,
    required Map<int, String> accountNames,
    required String currency,
    required String dateRangeStr,
    String themeName = 'classic',
  }) async {
    final pdf = pw.Document();

    // Theme definition
    PdfColor primaryColor;
    PdfColor cardBg;
    switch (themeName.toLowerCase()) {
      case 'modern_blue':
        primaryColor = PdfColors.indigo900;
        cardBg = PdfColors.indigo50;
        break;
      case 'minimalist':
        primaryColor = PdfColors.grey900;
        cardBg = PdfColors.grey100;
        break;
      case 'premium_gold':
        primaryColor = PdfColors.orange900;
        cardBg = PdfColors.orange50;
        break;
      case 'classic':
      default:
        primaryColor = PdfColors.red900;
        cardBg = PdfColors.grey50;
        break;
    }

    // Calculate totals
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    final Map<String, double> categorySpends = {};

    for (var tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense') {
        totalExpense += tx.amount;
        final catName = categoryNames[tx.categoryId] ?? 'Other';
        categorySpends[catName] = (categorySpends[catName] ?? 0.0) + tx.amount;
      }
    }

    final double savings = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MONEY MANAGER',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      'Financial Summary Report - ${themeName.toUpperCase()} STYLE',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date Range: $dateRangeStr', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Generated: ${DateTime.now().toIso8601String().substring(0, 10)}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: primaryColor),
            pw.SizedBox(height: 16),

            // Summary Stats Cards Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('TOTAL INFLOW', _formatPdfCurrency(totalIncome, currency), PdfColors.green900, cardBg),
                _buildStatCard('TOTAL OUTFLOW', _formatPdfCurrency(totalExpense, currency), PdfColors.red900, cardBg),
                _buildStatCard('NET SAVINGS', _formatPdfCurrency(savings, currency), savings >= 0 ? PdfColors.blue900 : PdfColors.red900, cardBg),
              ],
            ),
            pw.SizedBox(height: 24),

            // Spend By Category
            pw.Text(
              'EXPENSE BY CATEGORY',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 8),
            if (categorySpends.isEmpty)
              pw.Text('No expenses logged in this period.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))
            else
              pw.Table(
                border: const pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
                children: categorySpends.entries.map((entry) {
                  final percent = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        child: pw.Text(entry.key, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        child: pw.Text('${percent.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(_formatPdfCurrency(entry.value, currency), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            pw.SizedBox(height: 24),

            // Transactions Table
            pw.Text(
              'TRANSACTION LEDGER',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: const pw.TableBorder(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                horizontalInside: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
              ),
              columnWidths: const {
                0: pw.FixedColumnWidth(60),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(2),
                4: pw.FixedColumnWidth(60),
              },
              children: [
                // Table Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('DATE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('TITLE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('CATEGORY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('ACCOUNT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text('AMOUNT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                // Data Rows
                ...transactions.map((tx) {
                  final catName = categoryNames[tx.categoryId] ?? 'Other';
                  final accName = accountNames[tx.accountId] ?? 'Account';
                  final sign = tx.type == 'income' ? '+' : '-';
                  final color = tx.type == 'income' ? PdfColors.green900 : PdfColors.red900;

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(tx.date.toIso8601String().substring(0, 10), style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(tx.title, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(catName, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(accName, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            '$sign${_formatPdfCurrency(tx.amount, currency)}',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: color),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    // Save and Share
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/money_manager_report_$themeName.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Financial Summary Report ($dateRangeStr)',
    );
  }

  static pw.Widget _buildStatCard(String title, String value, PdfColor color, PdfColor bg) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: bg,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  static String _formatPdfCurrency(double amount, String currencyCode) {
    return CurrencyFormatter.format(amount, currencyCode).replaceAll('₹', 'Rs.');
  }
}
